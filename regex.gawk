#! /bin/gawk -f
{
  print language_parser_handler($0)
}

function get_character_class(text) {
 if (match(text, /^digits?$/)) {
   return  "\\d"
 }
 if (match(text, /^characters?$/)) {
   return  "\\w"
 }
 if (match(text, /^spaces?$/)) {
   return  "\\s"
 }
 if (match(text, /^lletters?$/)) {
   return  "[a-z]"
 }
 if (match(text, /^uletters?$/)) {
   return  "[A-Z]"
 }
 if (match(text, /^oneormoretimes$/)) {
   return  "+"
 }
 if (match(text, /^morethanzerotimes$/)) {
   return  "*"
 }
 if (match(text, /^between([[:digit:]]+)and([[:digit:]]+)times$/, matched_digits)) {
   return "{" matched_digits[1] "," matched_digits[2] "}"
 }
 if (match(text, /^exactly([[:digit:]]+)times$/, matched_digits)) {
   return "{" matched_digits[1] "}"
 }
 if (match(text, /^atleast([[:digit:]]+)times$/, matched_digits)) {
   return "{" matched_digits[1] ",}"
 }
 if (match(text, /^optional(ly)?$/)) {
   return "?"
 } else {
   return text
 }
}

function capture_check(current_value,current_field_index,      tmp_return) {
#let's save that opening brace
  tmp_return = current_value
#keep grabbing the next input, starting at index + 1 so that I don't have to pass the "next" value to the language parser and instead pass in the "current"
  for (j = current_field_index + 1; !match($j, /^\)$/); j++) {
#as long as it isn't a closing paren parse it and keep on keepin on
     tmp_return = tmp_return language_parser($(j), j)
   }
  return tmp_return language_parser($(j), (j))
}

function literal_check(test_line,      tmp_return) {
 if (match(test_line, /"/)) {
#keep grabbing the next input
   while (getline tmp) {
#as long as it isn't the closing " use it and keep on keeping on
     if (match(tmp, /[^"]/)) {
       tmp_return = tmp_return tmp
     } else {
#we hit the closing ", nothing else to see here folks
       break
     }
   }
 }
 return tmp_return
}

function look_around_check(current_record,current_field_index,     tmp_return) {
  look_around_clause = current_record $(current_field_index + 1)
   tmp = language_parser($(current_field_index + 2), (current_field_index + 2))
   if (match(look_around_clause, "precededby")) {
     tmp_return =  "(?<=" tmp ")"
   } else if (match(look_around_clause, "followedby")) {
     tmp_return =  "(?=" tmp ")"
   } else if (match(look_around_clause, "notprecededby")) {
     tmp_return =  "(?<!" tmp ")"
   } else if (match(look_around_clause, "notfollowedby")) {
     tmp_return =  "(?!" tmp ")"
   }
 return tmp_return
}

function not_check(test_line,     tmp_return) {
  if (match(test_line, /^not$/)) {
#since we are notting we'll need a character class
    getline tmp
    tmp_return = "[^" language_parser(tmp) "]"
  }
  return tmp_return
}

function language_parser_handler(current_line,    output) {
  for (i=1; i <= NF; i++) {
    output = output language_parser($i, i)
  }
  return output
}

function language_parser(current_word, current_field_index,     parsed_value) {
  if (match(current_word, /^followed$/)) {
    switch ($(current_field_index + 1)) {
      case "by":
        parsed_value = look_around_check(current_word, current_field_index)
        break
    }
  } else if (match(current_word $(current_field_index + 1) , /^endswith$/)) {
    parsed_value = language_parser($(current_field_index + 2), (current_field_index + 2)) "$"
  } else if (match(current_word, /^\($/)) {
    parsed_value = capture_check(current_word, current_field_index)
  } else {
    parsed_value = get_character_class(current_word)
  }
  if (i < current_field_index) {
    i = current_field_index
  }
  return parsed_value
}

function print_space(k) {
  while(k) {
    printf(" ")
    k--
  }
}

#! /bin/gawk -f
{
  print language_parser_handler($0)
}

function language_parser_handler(current_line,    output) {
  #lets loop through each field and parse the important bits out
  for (i=1; i <= NF; i++) {
    output = output language_parser($i, i)
  }
  return output
}

#Current this function is going to be a bit messy and be a bunch of if/elseifs until I can think of a better way to handle parsing english
#it may end up staying this way, but get a bit of sprucing by using fancier regex to keep some of the nested if/switches to a minimum
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
  } else if (match(current_word, /^not$/)) {
    parsed_value = not_check(current_word, current_field_index)
  } else {
    parsed_value = get_character_class(current_word)
  }
  if (i < current_field_index) {
    i = current_field_index
  }
  return parsed_value
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
#this is super dirty, TODO clean it up
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
#we have the final language_parser here since we still need to parse the closing paren
  return tmp_return language_parser($(j), (j))
}

#TODO convert this
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
#this is sort of dirty.... TODO maybe come up with a better way of handling it
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

function not_check(current_value,current_field_index,     tmp_return) {
#since we are notting we'll need a character class
  tmp_return = "[^" language_parser($(current_field_index + 1), (current_field_index + 1 )) "]"
  return tmp_return
}

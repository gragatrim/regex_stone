#! /bin/gawk -f
BEGIN {
  RS="[[:space:]]"
#let's initialize our return variable
 unformatted_return = ""
#let's get our last "line" placeholder going
 last_line = ""
  }
{
unformatted_return = unformatted_return parse_handler($0);
  last_line = $0
}
END {
  printf "%s", unformatted_return
}

function parse_handler(record,      parsed_return) {
 if (parsed_return = parsed_return look_around_check(record, last_line)) {
#this handles lookarounds TODO actually make it handle them correctly
 } else if (parsed_return = parsed_return not_check(record)) {
#this handles literal strings
 } else if (parsed_return = parsed_return literal_check(record)) {
#this handles literal strings
 } else if (parsed_return = parsed_return capture_check(record)) {
#this handles capture groups
 } else if (parsed_return = parsed_return get_character_class(record)) {
#this handles getting things like \d, \w, \s
 } else {
   parsed_return = record
 }
  return parsed_return
}

function get_character_class(text) {
 if (match(text, /^beginswith$|^startswith$/)) {
   return "^"
 }
 if (match(text, /^endswith$/)) {
    getline tmp
    return parse_handler(tmp) "$"
 }
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
 }
}

function capture_check(test_line,      tmp_return) {
 if (match(test_line, /^\($/)) {
#let's print out that opening brace
   tmp_return = tmp_return test_line
#keep grabbing the next input
   while (getline tmp) {
#as long as it isn't a closing paren parse it and keep on keepin on
     if (match(tmp, /[^)]/)) {
       tmp_return = tmp_return parse_handler(tmp)
     } else {
#we hit the closing brace, nothing else to see here folks
       tmp_return = tmp_return ")"
       break
     }
   }
 }
 return tmp_return
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

function look_around_check(test_line,last_line,     tmp_return) {
 return ""
 if (match(test_line, /(not)?(followedby|precededby)/, look_direction)) {
  look_around_clause = look_direction[1] look_direction[2]
#keep grabbing the next input
   getline tmp
   if (match(look_around_clause, "precededby")) {
     tmp_return =  "(?<=" tmp ")" last_line
   } else if (match(look_around_clause, "followedby")) {
     tmp_return =  "(?=" tmp ")" last_line
   } else if (match(look_around_clause, "notprecededby")) {
     tmp_return =  "(?<!" tmp ")" last_line
   } else if (match(look_around_clause, "notfollowedby")) {
     tmp_return =  "(?!" tmp ")" last_line
   }
 }
 return tmp_return
}

function not_check(test_line,     tmp_return) {
  if (match(test_line, /^not$/)) {
#since we are notting we'll need a character class
    getline tmp
    tmp_return = "[^" parse_handler(tmp) "]"
  }
  return tmp_return
}

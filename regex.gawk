#! /bin/gawk -f
BEGIN { RS="[[:space:]]"}
{
#let's initialize our return variable
 unformatted_return = ""
#this needs to be first so that it nots the correct grouping
 if (match($0, /not/)) {
   unformatted_return = unformatted_return "^"
 }
unformatted_return = unformatted_return parse_handler($0);
printf "%s", unformatted_return
}

function parse_handler(record,      parsed_return) {
#this handles literal strings
  parsed_return = parsed_return literal_check(record)
#this handles capture groups
  parsed_return = parsed_return capture_check(record);
#this handles getting things like \d, \w, \s
  parsed_return = parsed_return get_character_class(record);
  return parsed_return
}

function get_character_class(text) {
 if (match(text, /digits?/)) {
   return  "\\d"
 }
 if (match(text, /characters?/)) {
   return  "\\w"
 }
 if (match(text, /spaces?/)) {
   return  "\\s"
 }
 if (match(text, /lletters?/)) {
   return  "[a-z]"
 }
 if (match(text, /uletters?/)) {
   return  "[A-Z]"
 }
 if (match(text, /oneormoretimes/)) {
   return  "+"
 }
 if (match(text, /morethanzerotimes/)) {
   return  "*"
 }
 if (match(text, /between([[:digit:]]+)and([[:digit:]]+)times/, matched_digits)) {
   return "{" matched_digits[1] "," matched_digits[2] "}"
 }
}

function capture_check(test_line,      tmp_return) {
 if (match(test_line, /\(/)) {
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

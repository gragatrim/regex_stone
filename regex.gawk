#! /bin/gawk -f
BEGIN {
  useless_words = "/a|the|any|all|with|/";
}
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
#THIS SHOULD ALWAYS BE FIRST!!!! no need to parse anything if the word is useless
  if (match(current_word, useless_words)) {
#This is done so that things like ends with will still work and get the expected regex instead of just getting nothing
    parsed_value = language_parser($(current_field_index + 1), (current_field_index + 1))
  } else if (match(current_word, /"/)) {
    parsed_value = literal_check(current_field_index)
  } else if (match(current_word, /^followed$/) || match(current_word, /^preceded$/)) {
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
    if (!(match($(current_field_index + 1), /^followed$/) || match($(current_field_index + 1), /^preceded$/))) {
    parsed_value = not_check(current_word, current_field_index)
    } else {
#we don't need to do anything here as the check for followed/preceded should handle this
    }
  } else if (match(current_word, /^one$/) &&
             match($(current_field_index + 1), /^or$/) &&
             match($(current_field_index + 2), /^more$/) &&
             match($(current_field_index + 3), /^times$/)) {
    parsed_value =  "+"
    i = current_field_index + 3
  } else if (match(current_word, /^more$/) &&
             match($(current_field_index + 1), /^than$/) &&
             match($(current_field_index + 2), /^zero$/) &&
             match($(current_field_index + 3), /^times$/)) {
    parsed_value =  "*"
    i = current_field_index + 3
  } else if (match(current_word, /^between$/) &&
             match($(current_field_index + 1), /^[[:digit:]]+$/, beginning_digit) &&
             match($(current_field_index + 2), /^and$/) &&
             match($(current_field_index + 3), /^[[:digit:]]+$/, ending_digit) &&
             match($(current_field_index + 4), /^times$/)) {
    parsed_value = "{" beginning_digit[0] "," ending_digit[0] "}"
    i = current_field_index + 4
  } else if (match(current_word, /^exactly$/) &&
             match($(current_field_index + 1), /^[[:digit:]]+$/, matched_digits) &&
             match($(current_field_index + 2), /^times$/)) {
    parsed_value = "{" matched_digits[0] "}"
    i = current_field_index + 2
  } else  if (match(current_word, /^atleast$/) &&
              match($(current_field_index + 1), /^[[:digit:]]+$/, matched_digits) &&
              match($(current_field_index + 2), /^times$/)) {
    parsed_value = "{" matched_digits[0] ",}"
    i = current_field_index + 2
  } else if (match(current_word, /^uppercase$/) && match($(current_field_index + 1), /^letters?$/)) {
    parsed_value = get_character_class("uletter")
    i = current_field_index + 1
  } else if (match(current_word, /^lowercase$/) && match($(current_field_index + 1), /^letters?$/)) {
    parsed_value = get_character_class("lletter")
    i = current_field_index + 1
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
#This fixes multi word identifiers used inside of a capture group
     if (i > j) {
       j = i
     }
   }
#we have the final language_parser here since we still need to parse the closing paren
  return tmp_return language_parser($(j), (j))
}

function literal_check(current_field_index,      tmp_return) {
#keep grabbing the next input, starting at index + 1 so that I don't have to pass the "next" value to the language parser and instead pass in the "current"
  for (j = current_field_index + 1; !match($j, /^\"$/); j++) {
#as long as it isn't the closing " use it and keep on keeping on
     tmp_return = tmp_return " " $j
#SUPER FUCKING HACKY!!! Not sure how to handle this otherwise though.... TODO Make this suck less
     language_parser("", j)
   }
#and the hacks just keep on coming.... I really need to figure out a better way to do literal strings.... TODO Make this suck less
     language_parser("", j)
 return tmp_return
}

function look_around_check(current_record,current_field_index,     tmp_return) {
#this is sort of dirty.... TODO maybe come up with a better way of handling it
  look_around_clause_two = current_record $(current_field_index + 1)
  look_around_clause_three = $(current_field_index - 1) current_record $(current_field_index + 1)
   tmp = language_parser($(current_field_index + 2), (current_field_index + 2))
#The three value should go first as the two will always catch in these cases, and we actually want to give the not a chance
   if (match(look_around_clause_three, "notprecededby")) {
     tmp_return =  "(?<!" tmp ")"
   } else if (match(look_around_clause_three, "notfollowedby")) {
     tmp_return =  "(?!" tmp ")"
   } else if (match(look_around_clause_two, "precededby")) {
     tmp_return =  "(?<=" tmp ")"
   } else if (match(look_around_clause_two, "followedby")) {
     tmp_return =  "(?=" tmp ")"
   }
 return tmp_return
}

function not_check(current_value,current_field_index,     tmp_return) {
#since we are notting we'll need a character class
  tmp_return = "[^" language_parser($(current_field_index + 1), (current_field_index + 1 )) "]"
  return tmp_return
}

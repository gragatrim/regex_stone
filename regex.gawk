#! /bin/gawk -f
BEGIN {
  useless_words = "^(a|the|any|all|with)$";
}
/^[^#]/{
  print $0 " -> " language_parser_handler($0)
}

# This function just calls the language parser function for us
#
# @args global current_line This is the the entire line i.e. $0
# @args local  output       This is the parsed output that will be returned to the console
#
# @return This returns the parsed output for the line so it can be output to the console
function language_parser_handler(current_line,    output) {
  #lets loop through each field and parse the important bits out
  for (i=1; i <= NF; i++) {
    output = output language_parser($i, i)
  }
  return output
}

# Current this function is going to be a bit messy and be a bunch of if/elseifs until I can think of a better way to handle parsing english
# it may end up staying this way, but get a bit of sprucing by using fancier regex to keep some of the nested if/switches to a minimum
# Basically it is doing all of the heavy lifting and determinig what should be parsed by what function
#
# @arg global current_word        This is the current field we are working on e.g. $1, $2
# @arg global current_field_index This is the index for the current field we are parsing. If we were parsing $23, this would be 23
# @arg local  parsed_value        This is a local variable that we use to organize what will be returned by this function
#
# @return This returns the parsed output of the field passed in
function language_parser(current_word, current_field_index,    parsed_value) {
#THIS SHOULD ALWAYS BE FIRST!!!! no need to parse anything if the word is useless
  if (match(current_word, useless_words)) {
#This is done so that things like ends with will still work and get the expected regex instead of just getting nothing
    parsed_value = language_parser($(current_field_index + 1), (current_field_index + 1))
  } else if (match(current_word, /^"/)) {
    parsed_value = literal_check(current_field_index)
  } else if (match(current_word, /^followed$/) || match(current_word, /^preceded$/)) {
    switch ($(current_field_index + 1)) {
      case "by":
        parsed_value = look_around_check(current_word, current_field_index)
        break
    }
  } else if (match(current_word $(current_field_index + 1) , /^endswith$/)) {
#We'll always want to parse the value below, the only thing that will change is when/where the $ goes
      parsed_value = language_parser($(current_field_index + 2), (current_field_index + 2))
#We need to use i here instead of current_field_index due to how the current_field_index changes after the last parsing
    if (quantifier_check(i + 1)) {
#There is a quantifier after, we need to parse that before tossing in the $
      parsed_value = parsed_value language_parser($(i + 1), i + 1)  "$"
    } else {
      parsed_value = parsed_value "$"
    }
  } else if (match(current_word, /^\($/)) {
    parsed_value = capture_check(current_word, current_field_index)
  } else if (match(current_word, /^not$/)) {
    if (!(match($(current_field_index + 1), /^followed$/) || match($(current_field_index + 1), /^preceded$/))) {
    parsed_value = not_check(current_field_index)
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

# This returns the character class equivalents for the values passed in
#
# @arg global text This is the text that is passed in and should be a character class
#
# @return This returns the character class, or if one isn't found, it returns what was passed in(this is going to change eventually. TODO remove the default at some point
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

# This is how we check for capture groups
#
# @arg global current_value       This is the current field's value being passed in
# @arg global current_field_index This is the index of the field that was passed in
# @arg local  tmp_return          This holds the partial return for capture groups(either due to more than one parsable input between braces, or nested capture groups
#
# @return This returns the parsed capture group
function capture_check(current_value,current_field_index,    tmp_return) {
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

# This handles literal strings that need parsing
#
# @arg global current_field_index This is the index of the current field being parsed
# @arg local  tmp_return          This holds the partial return for literal groups(either due to more than one parsable input between quotes, or nested literal groups
#
# @return The exact words between quotes
function literal_check(current_field_index,    tmp_return) {
#This checks if we are doing a single value in the literal
  if (match($(current_field_index), /\"$/)) {
    tmp_return = tmp_return substr($(current_field_index), 2, length($(current_field_index)) - 2)
  } else {
#if we aren't then we need to continue to print out the rest of the string until we hit the next "(which is hopefully the closing quote)
    tmp_return = tmp_return substr($(current_field_index), 2)
#start at the next field index since we already added in the first one
    for (j = current_field_index + 1; !match($j, /\"$/); j++) {
#as long as it isn't the closing " use it and keep on keeping on
      tmp_return = tmp_return " " $j
#SUPER FUCKING HACKY!!! Not sure how to handle this otherwise though.... TODO Make this suck less
      language_parser("", j)
    }
#we hit the end of the road, time to print out the final set of characters, minus the closing quote
    tmp_return = tmp_return " " substr($j, 1, length($j) - 1)
  }
#and the hacks just keep on coming.... I really need to figure out a better way to do literal strings.... TODO Make this suck less
  language_parser("", j)
  return tmp_return
}

# This handles look ahead/behinds
#
# @arg global current_record      This is the current field being parsed
# @arg global current_field_index This is the index of the field being parsed
# @arg local  tmp_return          This holds the partial return for lookaround groups
#
# @return This returns the parsed look ahead/behind
function look_around_check(current_record,current_field_index,    tmp_return) {
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

# This handles parsing not
#
# @arg global current_field_index This is the current field's index
# @arg local  tmp_return          This holds the partial return for lookaround groups
#
# @return This returns the notted value
function not_check(current_field_index,    tmp_return) {
#since we are notting we'll need a character class
  tmp_return = "[^" language_parser($(current_field_index + 1), (current_field_index + 1 )) "]"
  return tmp_return
}

# This checks if the next value is a quantifier or not, this is especially useful for making sure ends with is being parsed correctly
#
# @arg global current_field_index This is the field's current index
# @arg local  tmp_return          This is either 0 if the next field isn't a quantifier, or 1 if it is
#
# @return This returns a 0 if the next field isn't a quantifier, or a 1 if it is
function quantifier_check(current_field_index,    tmp_return) {
#Here we'll use a bunch of duplicate code to check if a modifier comes next for use with things like "ends with"
  tmp_return = 0
  if (match($(current_field_index), useless_words)) {
    tmp_return = quantifier_check(current_field_index + 1)
  } else if (match($(current_field_index), /^one$/) &&
             match($(current_field_index + 1), /^or$/) &&
             match($(current_field_index + 2), /^more$/) &&
             match($(current_field_index + 3), /^times$/)) {
      tmp_return = 1
  } else if (match($(current_field_index), /^more$/) &&
             match($(current_field_index + 1), /^than$/) &&
             match($(current_field_index + 2), /^zero$/) &&
             match($(current_field_index + 3), /^times$/)) {
      tmp_return = 1
  } else if (match($(current_field_index), /^between$/) &&
             match($(current_field_index + 1), /^[[:digit:]]+$/, beginning_digit) &&
             match($(current_field_index + 2), /^and$/) &&
             match($(current_field_index + 3), /^[[:digit:]]+$/, ending_digit) &&
             match($(current_field_index + 4), /^times$/)) {
      tmp_return = 1
  } else if (match($(current_field_index), /^exactly$/) &&
             match($(current_field_index + 1), /^[[:digit:]]+$/, matched_digits) &&
             match($(current_field_index + 2), /^times$/)) {
      tmp_return = 1
  } else  if (match($(current_field_index), /^atleast$/) &&
              match($(current_field_index + 1), /^[[:digit:]]+$/, matched_digits) &&
              match($(current_field_index + 2), /^times$/)) {
      tmp_return = 1
  }
  return tmp_return
}

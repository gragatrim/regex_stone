regex_stone
===========

This will convert regular English sentences/ideas into their regex equivalents
The end goal will be to take something in the form

Any digit followed by any lowercase letter one or more times

and it should return

\d(?=[a-z])+

This script is run from the command line using gawk. You can run it by echoing out a string and piping it to this like so

echo "ends with ( spaces ( digits ) ) characters spaces" | regex.gawk

Or you can cat a file like so

cat testfile | regex.gawk

If there are other ways for you to generate text that can be piped to this script it should work and return the correct regex

 as of commit 

3ac29285152784262504e3897371373a8e82d112

The following sentence 

ends with any digit one or more times followed by ( characters ) " testing one ends with " not digits followed by characters 

produces the following output

\d$+(?=(\w)) testing one ends with[^\d](?=\w)

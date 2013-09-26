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

e8da476db7e62b0b3c25c6561fc11f4917bd454a

The following sentence

ends with any digit atleast 1 times followed by ( uppercase letters one or more times ( followed by spaces more than zero times ) ) "testing one ends with" not digits followed by characters

produces the following output

\d{1,}$(?=([A-Z]+((?=\s)*)))testing one ends with[^\d](?=\w)

Make sure to check the raw output as github does some fancy things and can turn the above regex into a link.

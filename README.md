regex_stone
===========

This will convert regular English sentences/ideas into their regex equivalents
The end goal will be to take something in the form

Any digit followed by any lowercase letter one or more times

and it should return

\d[a-z]+

In the interim I'm grouping all words together as spaces are my record separator. Currently the following

beginswith ( digits exactly2times ) not space ( digits exactly2times ) not space endswith ( digits exactly4times )

returns

^(\d{2})[^\s](\d{2})[^\s](\d{4})$

This script is run from the command line using gawk. You can run it by echoing out a string and piping it to this like so

echo "digits exactly8times" | regex.gawk

Or you can cat a file like so

cat testfile | regex.gawk

If there are other ways for you to generate text that can be piped to this script it should work and return the correct regex

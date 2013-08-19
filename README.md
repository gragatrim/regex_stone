regex_stone
===========

This will convert regular English sentences/ideas into their regex equivalents
The end goal will be to take something in the form

Any digit followed by any lowercase letter one or more times

and it should return

\d[a-z]+

In the interim I'm grouping all words together as spaces are my record separator. Currently the following

echo "not ( ( digits ) oneormoretimes ) lletters morethanzerotimes uletters" | ./regex.gawk

returns

^((\d)+)[a-z]*[A-Z]

[![Build Status](https://secure.travis-ci.org/JoshCheek/line.png?branch=master)](http://travis-ci.org/JoshCheek/line)

Line
====

Command line tool to print the lines from stdinput that are matched by the matchers
e.g. `line 1` prints the first line


    Usage: line [options] matchers

    matchers:
      2      matches the second line
      -2     matches the second from the last line
      ^2     matches lines other than the second
      1..10  matches lines 1 through 10 (the numbers can be negative)
      ^5..10 matches all lines before the fifth and all lines after the tenth

    options:
      -l, --line-numbers  show line numbers in output
      -s, --strip         strip leading and tailing whitespace
      -f, --force         do not err when told to print a line number beyond the input
      -c, --chomp         no newlines between lines in the output
      -h, --help          this help screen

    examples:
      line 1 22         # prints lines 1 and 22
      line -1           # prints the last line
      line ^1 ^-1       # prints all lines but the first and the last
      line 1..10        # prints lines 1 through 10
      line 5..-5        # prints all lines except the first and last four
      line ^5..10       # prins all lines except 5 through ten
      line 5..10 ^6..8  # prints lines 5, 9, 10
      line 5..10 ^7     # prints lines 5, 6, 8, 9

License
=======

           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                       Version 2, December 2004

    Copyright (C) 2012 Josh Cheek <josh.cheek@gmail.com>

    Everyone is permitted to copy and distribute verbatim or modified
    copies of this license document, and changing it is allowed as long
    as the name is changed.

               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
      TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

     0. You just DO WHAT THE FUCK YOU WANT TO.


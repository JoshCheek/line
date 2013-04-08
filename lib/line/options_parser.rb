require 'line/options'
require 'line/matchers'

class Line
  class OptionParser
    def self.call(*args)
      new(*args).call
    end

    def initialize(arguments)
      @arguments = arguments
    end

    def call
      return @options if @options
      self.options = Options.new

      @arguments.each do |arg|
        case arg
        when '-l', '--line-numbers' then options.line_numbers = true
        when '-h', '--help'         then options.show_help    = true
        when '-s', '--strip'        then options.strip        = true
        when '-f', '--force'        then options.force        = true
        when '-c', '--chomp'        then options.chomp        = true
        when '-d', '--debug'        then options.debug        = true
        when '0'                    then invalid_args << arg
        # range
        when /\A-?\d+..-?\d+/
          lower, upper = arg.split('..').map(&:to_i)
          options.indexes   << lower << upper
          positive_matchers << Matchers::Range.new(lower, upper)
        # index
        when /\A-?\d+\Z/
          index = arg.to_i
          options.indexes   << index
          positive_matchers << Matchers::Index.new(index)
        # negated index
        when /\A\^-?\d+\Z/
          index = arg[1..-1].to_i
          options.indexes   << index
          negative_matchers << Matchers::Not.new(Matchers::Index.new(index))
        when /\A\^-?\d+..-?\d+\Z/
          lower, upper = arg[1..-1].split('..').map(&:to_i)
          options.indexes   << lower << upper
          negative_matchers << Matchers::Not.new(Matchers::Range.new(lower, upper))
        else
          invalid_args << arg
        end
      end

      options.errors[:line_numbers] = error_msg_for_line_numbers if error_msg_for_line_numbers
      options.line_matcher          = consolidate_args_to_line_matcher
      options.buffer_size           = [0, *options.indexes].min.abs
      options.help_screen           = help_screen
      options
    end

    private

    attr_accessor :options

    def error_msg_for_line_numbers
      if invalid_args.size == 1
        "#{invalid_args.first.inspect} is not a valid line number, offsets start from 1"
      elsif invalid_args.size > 1
        inspected_args = invalid_args.map(&:inspect)
        inspected_args[-1] = "and #{inspected_args[-1]}"
        "#{inspected_args.join ', '} are not valid line numbers, offsets start from 1"
      elsif positive_matchers.empty? && negative_matchers.empty? && !options.line_numbers?
        'No matchers provided'
      end
    end

    def consolidate_args_to_line_matcher
      positive_matcher = positive_matchers.inject(Matchers::MatchNothing.new)    { |memo, current| Matchers::Or.new  memo, current }
      negative_matcher = negative_matchers.inject(Matchers::MatchEverything.new) { |memo, current| Matchers::And.new memo, current }

      if    positive_matchers.any? && negative_matchers.any? then Matchers::And.new positive_matcher, negative_matcher
      elsif positive_matchers.any?                           then positive_matcher
      elsif negative_matchers.any?                           then negative_matcher
      else                                                        Matchers::MatchEverything.new
      end
    end

    def invalid_args
      @invalid_args ||= []
    end

    def negative_matchers
      @negative_matchers ||= []
    end

    def positive_matchers
      @positive_matchers ||= []
    end

    def help_screen
      <<-HELP.gsub(/^      /, '')
      Usage: line [options] matchers

      Prints the lines from stdinput that are matched by the matchers
      e.g. `line 1` prints the first line

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
      HELP
    end
  end
end

class Line
  module Matchers
    module Helpers
      def inspect_helper(parent, inspected, has_children)
        return inspected        if parent && parent.class == self.class
        return "(#{inspected})" if parent && has_children
        return inspected        if parent
        "Matcher(#{inspected})"
      end
    end

    class Or
      include Helpers

      def initialize(matcher1, matcher2)
        @matcher1, @matcher2 = matcher1, matcher2
      end

      def matches?(*args)
        @matcher1.matches?(*args) || @matcher2.matches?(*args)
      end

      def inspect(parent=false)
        inspect_helper parent, "#{@matcher1.inspect self} || #{@matcher2.inspect self}", true
      end
    end

    class And
      include Helpers

      def initialize(matcher1, matcher2)
        @matcher1, @matcher2 = matcher1, matcher2
      end

      def matches?(*args)
        @matcher1.matches?(*args) && @matcher2.matches?(*args)
      end

      def inspect(parent=false)
        inspect_helper parent, "#{@matcher1.inspect self} && #{@matcher2.inspect self}", true
      end
    end

    class MatchEverything
      include Helpers

      def matches?(*)
        true
      end

      def inspect(parent=false)
        inspect_helper parent, "MatchEverything", false
      end
    end

    class MatchNothing
      include Helpers

      def matches?(*)
        false
      end

      def inspect(parent=false)
        inspect_helper parent, "MatchNothing", false
      end
    end

    class Index
      include Helpers

      attr_accessor :index

      def initialize(index)
        self.index = index
      end

      def matches?(line, positive_index, negative_index)
        positive_index == index || negative_index == index
      end

      def inspect(parent=false)
        inspect_helper parent, index.to_s, false
      end
    end

    class Range
      include Helpers

      attr_accessor :lower, :upper

      def initialize(lower, upper)
        self.lower, self.upper = lower, upper
      end

      def matches?(line, positive_index, negative_index)
        if    negative_index && lower < 0 && upper < 0 then lower <= negative_index && negative_index <= upper
        elsif negative_index && lower < 0              then lower <= negative_index && positive_index <= upper
        elsif negative_index && upper < 0              then lower <= positive_index && negative_index <= upper
        elsif 0 < lower && 0 < upper                   then lower <= positive_index && positive_index <= upper
        elsif 0 < lower                                then lower <= positive_index
        elsif 0 < upper                                then positive_index <= upper
        else                                                false
        end
      end

      def inspect(parent=false)
        inspect_helper parent, "#{lower}..#{upper}", false
      end
    end

    class Not
      include Helpers

      attr_accessor :matcher

      def initialize(matcher)
        self.matcher = matcher
      end

      def matches?(line, positive_index, negative_index)
        !matcher.matches?(line, positive_index, negative_index)
      end

      def inspect(parent=false)
        inspect_helper parent, "^#{matcher.inspect self}", true
      end
    end
  end

  class Options
    attr_accessor :show_help, :strip, :force, :chomp, :indexes, :errors, :line_matcher, :line_numbers
    attr_accessor :instream, :outstream, :errstream, :help_screen, :buffer_size, :debug

    def initialize(attributes={})
      update attributes
      yield self if block_given?
    end

    def update(attributes)
      attributes.each { |attribute, value| __send__ "#{attribute}=", value }
      self
    end

    alias line_numbers? line_numbers
    alias show_help?    show_help
    alias debug?        debug
    alias strip?        strip
    alias force?        force
    alias chomp?        chomp

    def help_screen
      @help_screen ||= ''
    end

    def indexes
      @indexes ||= []
    end

    def errors
      @errors ||= {}
    end

    def instream
      @instream ||= $stdin
    end

    def outstream
      @outstream ||= $stdout
    end

    def errstream
      @errstream ||= $stderr
    end

    def buffer_size
      @buffer_size ||= 0
    end
  end

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

  def self.call(*args)
    new(*args).call
  end

  attr_accessor :options

  def initialize(options)
    @options = options
  end

  def call
    print_matcher if options.debug?

    if options.show_help?
      print_help
      return 0
    end

    if options.errors.any?
      print_errors
      return 1
    end

    print_lines

    if unseen_indexes.any? && !options.force?
      print_unseen_indexes
      return 1
    end

    return 0
  end

  private

  attr_accessor :max_index

  def unseen_indexes
    @unseen_indexes ||= options.indexes.dup
  end

  def print_help
    options.outstream.puts options.help_screen
  end

  def print_matcher
    options.errstream.puts options.line_matcher.inspect
  end

  def high_indexes
    @high_indexes ||= options.indexes.select { |index| index > max_index }
  end

  def print_errors
    options.errors.each do |type, message|
      options.errstream.puts message
    end
  end

  def print_unseen_indexes
    options.errstream.puts "Only saw #{max_index} lines of input, can't print lines: #{unseen_indexes.join ', '}"
  end

  def print_lines
    each_line do |line, positive_index, negative_index|
      unseen_indexes.delete positive_index
      unseen_indexes.delete negative_index
      next unless options.line_matcher.matches? line, positive_index, negative_index
      line = line.strip                   if options.strip?
      line = "#{positive_index}\t#{line}" if options.line_numbers?
      if options.chomp?
        options.outstream.print line.chomp
      else
        options.outstream.puts line
      end
    end
  end

  def each_line
    each_line = options.instream.each_line.method(:next)
    QueueWithIndexes.new(options.buffer_size, &each_line).each do |line, positive_index, negative_index|
      positive_index += 1
      self.max_index = positive_index
      debug_line line, positive_index, negative_index
      yield line, positive_index, negative_index
    end
  end

  def debug_line(line, positive_index, negative_index)
    return unless options.debug?
    options.errstream.puts "#{line.inspect}, #{positive_index.inspect}, #{negative_index.inspect}"
  end
end

class QueueWithIndexes
  def initialize(num_negatives=0, &input_generator)
    self.positive_index  = 0
    self.buffer          = []
    self.num_negatives   = num_negatives
    self.input_generator = input_generator
  end

  include Enumerable

  def each(&block)
    return to_enum :each unless block
    fill_the_buffer             until dry_generator? || full_buffer?
    flow_through_buffer(&block) until dry_generator?
    drain_the_buffer(&block)    until empty?
    self
  end

  def empty?
    fill_the_buffer
    buffer.empty?
  end

  private

  attr_accessor :dry_generator, :positive_index, :buffer, :num_negatives, :input_generator
  alias dry_generator? dry_generator

  def full_buffer?
    num_negatives <= buffer.size
  end

  def fill_the_buffer
    input = generate_input
    buffer << input unless dry_generator?
  end

  def flow_through_buffer(&block)
    flow_in = generate_input
    return if dry_generator?
    buffer << flow_in
    flow_out = buffer.shift
    block.call [flow_out, increment_index, nil]
  end

  def drain_the_buffer(&block)
    negative_index = -buffer.size
    value = buffer.shift
    block.call [value, increment_index, negative_index]
  end

  def generate_input
    input_generator.call
  rescue StopIteration
    self.dry_generator = true
  end

  def increment_index
    old_index = positive_index
    self.positive_index = positive_index + 1
    old_index
  end
end



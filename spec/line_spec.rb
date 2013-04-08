require 'spec_helper'

require 'surrogate/rspec'

class MatchIndexes
  def initialize(is_positive, *indexes)
    @positive  = is_positive
    @indexes   = indexes
    @unmatched = []
    @matched   = []
  end

  attr_reader :indexes, :matched, :unmatched, :matcher, :positive

  alias positive? positive

  def matches?(matcher)
    @matcher = matcher

    self.indexes.each do |index|
      index.kind_of?(Array) ? indexes = index :
      index < 0             ? indexes = [0, index] :
                              indexes = [index, nil]

      if matcher.matches? '', *indexes
        matched << index
      else
        unmatched << index
      end
    end

    positive? ?  unmatched.empty? : matched.empty?
  end

  def failure_message_for_should(*)
    if positive?
      "#{matcher.inspect} should have matched #{unmatched.inspect}"
    else
      "#{matcher.inspect} shouldn't have matched #{matched.inspect}"
    end
  end
end

def match_indexes(*indexes)
  MatchIndexes.new(true, *indexes)
end
alias match_index match_indexes

def match_no_indexes(*indexes)
  MatchIndexes.new(false, *indexes)
end
alias match_index match_indexes

describe 'match_indexes (fucking helpers are too complex -.-)' do

  class MatcherInterface
    Surrogate.endow self
    define(:matches?) { |line, positive_index, negative_index| true }
    define(:inspect)  { |parent=nil| }
  end

  let(:spy) { MatcherInterface.new }

  specify 'Matchers implement the MatcherInterface' do
    Line::Matchers::Index.should substitute_for MatcherInterface, subset: true, names: true
  end

  it 'returns true when they match single positive indexes' do
    spy.will_matches? true
    match_indexes(1, 2).matches?(spy).should be_true
    spy.will_matches? false
    match_indexes(1, 2).matches?(spy).should be_false
  end

  it 'passes positive indexes in the positive index parameter, and nil as the negative index' do
    match_indexes(1, 2).matches?(spy).should be_true
    spy.was asked_if(:matches?).with(anything, 1, nil)
    spy.was asked_if(:matches?).with(anything, 2, nil)
  end

  it 'passes negative indexes in the negative index parameter' do
    match_indexes(1, -2).matches?(spy).should be_true
    spy.was asked_if(:matches?).with('', 1, nil)
    spy.was asked_if(:matches?).with('', anything, -2)
  end

  it 'passes the first and second element in an array to the pos/neg index parameters' do
    match_index([100, -100], [200, nil]).matches?(spy)
    spy.was asked_if(:matches?).with('', 100, -100)
    spy.was asked_if(:matches?).with('', 200, nil)
  end
end

def parse(args)
  Line::OptionParser.call(args)
end

def index_matcher(index)
  Line::Matchers::Index.new index
end

def index_matchers(*indexes)
  indexes.map { |index| index_matcher index }
end

def universal_matcher
  Line::Matchers::MatchEverything.new
end

describe Line::Options do
  let(:options) { described_class.new }

  it 'takes a hash of key/value pairs that it sets' do
    options = described_class.new(instream: 1, outstream: 2)
    options.instream.should == 1
    options.outstream.should == 2
  end

  it 'sets the instream to stdin by default' do
    options.instream.should == $stdin
    options.instream = 123
    options.instream.should == 123
  end

  it 'sets the outstream to stdout by default' do
    options.outstream.should == $stdout
    options.outstream = 123
    options.outstream.should == 123
  end

  it 'sets the errstream to stderr by default' do
    options.errstream.should == $stderr
    options.errstream = 123
    options.errstream.should == 123
  end

  specify 'indexes defaults to an empty collection' do
    options.indexes.should == []
    options.indexes.should equal options.indexes
  end

  specify 'errors defaults to an empty hash' do
    options.errors.should == {}
    options.errors.should equal options.errors
  end

  specify 'the help screen defaults to an empty string' do
    options.help_screen.should == ''
    options.help_screen = 'help screen'
    options.help_screen.should == 'help screen'
  end

  specify 'buffer_size is 0 by default' do
    options.buffer_size.should == 0
    options.buffer_size = 123
    options.buffer_size.should == 123
  end
end

describe Line::OptionParser do
  specify 'it sets the help screen on the options' do
    parse([]).help_screen.tap do |help|
      help.should include '-h'
      help.should include '-s'
      help.should include '-f'
      help.should include '-c'
      help.should include '-l'
    end
  end

  specify '-h, --help sets show_help?' do
    parse([]).show_help?.should be_false
    parse(['-h']).show_help?.should be_true
    parse(['--help']).show_help?.should be_true
  end

  specify '-s, --strip sets strip' do
    parse([]).strip?.should be_false
    parse(['-s']).strip?.should be_true
    parse(['--strip']).strip?.should be_true
  end

  specify '-f, --force sets force' do
    parse([]).force?.should be_false
    parse(['-f']).force?.should be_true
    parse(['--force']).force?.should be_true
  end

  specify '-c, --chomp sets chomp' do
    parse([]).chomp?.should be_false
    parse(['-c']).chomp?.should be_true
    parse(['--chomp']).chomp?.should be_true
  end

  specify '-l, --line-numbers sets the line numbers option' do
    parse([]).line_numbers?.should be_false
    parse(['-l']).line_numbers?.should be_true
    parse(['--line-numbers']).line_numbers?.should be_true
  end

  specify '-l matches everything when no other matchers are provided' do
    parse(['-l']).line_matcher.should match_indexes *1..5
    parse(['-l', '1']).line_matcher.should match_index 1
    parse(['-l', '1']).line_matcher.should match_no_indexes 0, -1
  end

  specify '-d sets debug' do
    parse([]).debug?.should be_false
    parse(['-d']).debug?.should be_true
  end

  it 'sets the buffer_size to 0 if there are no negative indexes' do
    parse(['1']).buffer_size.should == 0
  end

  it 'sets the buffer_size such that it can access all the negative numbers' do
    parse(['1', '-1', '-3', '-2', '10']).buffer_size.should == 3
  end

  it 'has errors when no matchers are provided and -l is not set' do
    parse(['1']).errors.should_not have_key :line_numbers
    parse(['-l']).errors.should_not have_key :line_numbers
    parse([]).errors[:line_numbers].should == "No matchers provided"
  end

  it 'has errors for 0, informing user that offset starts at 1' do
    parse(['1']).errors.should_not have_key :line_numbers
    parse(['0']).errors[:line_numbers].should == '"0" is not a valid line number, offsets start from 1'
    parse(['0', 'a', 'b']).errors[:line_numbers].should == '"0", "a", and "b" are not valid line numbers, offsets start from 1'
  end

  context 'when given integral arguments (e.g. 1, -1)' do
    it 'has no errors' do
      parse(['1']).errors.should == {}
    end

    it 'sets the buffer size' do
      parse(['-5']).buffer_size.should == 5
    end

    it 'treats them as as lines to match' do
      parse(['-1', '1', '11']).indexes.should == [-1, 1, 11]
      matcher = parse(['-1', '1', '11']).line_matcher
      matcher.should match_indexes -1, 1, 11
      matcher.should match_no_indexes -2, 0, 2, 10, 12
    end
  end

  context 'when given ranges (e.g. 1..10, -5..-3)' do
    it 'has no errors' do
      parse(['1..10']).errors.should == {}
    end

    it 'puts the edges in the expected indexes' do
      parse(['5..8']).indexes.should == [5, 8]
      parse(['-8..-5']).indexes.should == [-8, -5]
    end

    it 'sets the buffer size' do
      parse(['-8..-5']).buffer_size.should == 8
      parse(['5..-5']).buffer_size.should  == 5
    end

    it 'creates a matcher that matches the range' do
      matcher = parse(['5..8']).line_matcher
      matcher.should match_indexes [5, -1], [5, nil], [5, -100000]
      matcher.should match_indexes [8, -1], [8, nil], [8, -100000]
      matcher.should match_indexes [6, -1], [6, nil], [6, -100000]
      matcher.should match_no_indexes [4, -1], [9, nil]

      matcher = parse(['-8..-5']).line_matcher
      matcher.should match_indexes -8, -7, -6, -5
      matcher.should match_no_indexes -9, -4

      matcher = parse(['5..-5']).line_matcher
      matcher.should match_indexes [5, -5], [6, nil], [6, -6]
      matcher.should match_no_indexes [4, nil], [4, -4], [4, -5], [5, -4]

      matcher = parse(['-5..5']).line_matcher
      matcher.should match_indexes    [5, -5], [5,  -4], [4, -5], [5, nil], [4, nil]
      matcher.should match_no_indexes [5, -6], [6, nil], [6, -5]
    end
  end

  context 'when given negated ranges (e.g. ^1..10, ^-5..-3)' do
    it 'has no errors' do
      parse(['^1..10']).errors.should == {}
    end

    it 'puts the edges in the expected indexes' do
      parse(['^5..8']).indexes.should == [5, 8]
      parse(['^-8..-5']).indexes.should == [-8, -5]
    end

    it 'sets the buffer size' do
      parse(['^-8..-5']).buffer_size.should == 8
      parse(['^5..-5']).buffer_size.should  == 5
    end

    it 'creates a matcher that matches the range', t:true do
      matcher = parse(['^5..8']).line_matcher
      matcher.should match_no_indexes [5, -1], [5, nil], [5, -100000]
      matcher.should match_no_indexes [8, -1], [8, nil], [8, -100000]
      matcher.should match_no_indexes [6, -1], [6, nil], [6, -100000]
      matcher.should match_indexes    [4, -1], [9, nil]

      matcher = parse(['^-8..-5']).line_matcher
      matcher.should match_no_indexes -8, -7, -6, -5
      matcher.should match_indexes    -9, -4

      matcher = parse(['^5..-5']).line_matcher
      matcher.should match_no_indexes [5, -5], [6, nil], [6, -6]
      matcher.should match_indexes    [4, nil], [4, -4], [4, -5], [5, -4]

      matcher = parse(['^-5..5']).line_matcher
      matcher.should match_no_indexes [5, -5], [5,  -4], [4, -5], [5, nil], [4, nil]
      matcher.should match_indexes    [5, -6], [6, nil], [6, -5]
    end

  end

  context 'when given negated numbers (e.g. ^1, ^-1)' do
    it 'has no errors' do
      parse(['^1']).errors.should == {}
    end

    it 'puts them in the expected indexes' do
      parse(['^1']).indexes.should == [1]
    end

    it 'sets the buffer size' do
      parse(['^-3']).buffer_size.should == 3
    end

    it 'creates a matcher that matches their negation' do
      parse(['^2', '^4', '^-2']).line_matcher.should match_indexes 1, 3, 5, -1, -3
      parse(['^2', '^4', '^-2']).line_matcher.should match_no_indexes 2, 4, -2
    end

    it 'ands them together, and then ors them with everything else' do
      matcher = parse(['^6', '5..9', '^8', '11']).line_matcher
      matcher.should match_indexes 5, 7, 9, 11
      matcher.should match_no_indexes 4, 6, 8, 10, 12
    end
  end
end

describe Line do
  let(:_stderr)    { StringIO.new }
  let(:_stdout)    { StringIO.new }
  let(:_stdin)     { StringIO.new 100.times.map { |i| "line#{i.next}" }.join("\n") }
  let(:args)       { ['-l'] }
  let(:options)    { parse(args).update errstream: _stderr, outstream: _stdout, instream: _stdin }
  let(:stderr)     { exitstatus; _stderr.string }
  let(:stdout)     { exitstatus; _stdout.string }
  let(:exitstatus) { described_class.new(options).call }

  context 'when there are errors' do
    it 'prints the errors to the error stream and has an exit status of 1' do
      options.errors = {whatever: "MAH ERRAH"}
      stderr.should == "MAH ERRAH\n"
      exitstatus.should == 1
    end
  end

  context 'when debug is set' do
    before { args << '-d' }
    it "prints the matcher's inspection to the errstream" do
      stderr.should include 'Matcher'
    end

    it "prints each line, and its indexes" do
      _stdin.string = "a\nb\nc\n"
      args << '-2'
      stderr.should include '"a\n", 1, nil'
      stderr.should include '"b\n", 2, -2'
      stderr.should include '"c\n", 3, -1'
    end
  end

  context 'when there are no errors' do
    it 'prints nothing to stderr, and has an exit status of 0' do
      options.errors = {}
      stderr.should == ""
      exitstatus.should == 0
    end
  end

  specify 'when show_help is set, it displays the help screen and exits with 0' do
    options.help_screen = 'HELPME'
    options.show_help   = true
    stderr.should == ''
    stdout.should == "HELPME\n"
    exitstatus.should == 0
  end

  it 'prints the input lines at the specified indexes, starting at 1' do
    args.replace %w[1 3]
    stdout.should == "line1\nline3\n"
  end

  it 'prints negative indexes from the end' do
    args.replace %w[98 100 -2]
    stdout.should == "line98\nline99\nline100\n"
  end

  context 'when there are not enough lines to print the given indexes' do
    it 'does not print an error and exits 0 when force is set' do
      args.replace %w[-f 101]
      exitstatus.should == 0
      stderr.should be_empty
    end

    it 'prints an error and exits 1 when force is not set' do
      args.replace %w[100 101 102 -100 -101]
      exitstatus.should == 1
      stderr.should == "Only saw 100 lines of input, can't print lines: 101, 102, -101\n"
    end
  end

  context 'when there is whitespace wrapping the lines' do
    before do
      _stdin.string = "  1  \n2"
      args.replace %w[1 2]
    end

    it 'does not print the whitespace when strip is set' do
      options.strip = true
      stdout.should == "1\n2\n"
    end

    it 'prints the whitespace when strip is not set' do
      options.strip = false
      stdout.should == "  1  \n2\n"
    end
  end

  context 'when chomp is set' do
    it 'does not print newlines between the input lines' do
      _stdin.string = "  1  \n2"
      args.replace %w[-c 1 2]
      stdout.should == "  1  2"
    end
  end

  context 'when line_numbers is set' do
    it 'prints the line numbers in front of the lines' do
      args.replace %w[1 2 -l]
      _stdin.string = "line1\nline2"
      stdout.should == "1\tline1\n2\tline2\n"
    end

    it 'does not interfere with other options' do
      args.replace %w[1 -s -l]
      _stdin.string = '  123  '
      stdout.should == "1\t123\n"
    end
  end
end

describe QueueWithIndexes do
  def generator
    values = ['a', 'b', 'c']
    lambda { values.shift || raise(StopIteration) }
  end

  it 'takes a function that generates values' do
    QueueWithIndexes.new(&generator).to_a.should == [['a', 0, nil], ['b', 1, nil], ['c', 2, nil]]
  end

  it 'stops reading from the generator once the input_generator raises StopIteration' do
    values = %w[a b c]
    queue = QueueWithIndexes.new do
      if values.empty?
        values = %w[a b c]
        raise StopIteration
      end
      values.shift
    end
    queue.map(&:first).should == %w[a b c]
    queue.map(&:first).should == []
  end

  it 'can be given a size, to determine how much to buffer in order to be able to tell you negative indexes' do
    QueueWithIndexes.new(2, &generator).to_a.should == [['a', 0, nil], ['b', 1, -2], ['c', 2, -1]]
  end

  example 'when the size given is greater than the number of values, every value has a negative index' do
    QueueWithIndexes.new(4, &generator).to_a.should == [['a', 0, -3], ['b', 1, -2], ['c', 2, -1]]
  end

  it 'is cool with each being called all multiple times and such' do
    queue = QueueWithIndexes.new(2, &generator)
    queue.take(1).should == [['a', 0, nil]]
    queue.take(1).should == [['b', 1, -2]]
    queue.take(1).should == [['c', 2, -1]]
    queue.take(1).should == []
  end

  specify '#each returns the queue' do
    queue = QueueWithIndexes.new(&generator)
    queue.each {}.should equal queue
  end

  specify '#each is lazy' do
    QueueWithIndexes.new(&generator).each.map { 1 }.should == [1, 1, 1]
  end

  describe 'empty?' do
    it 'is true when there are no elements in the input' do
      QueueWithIndexes.new { raise StopIteration }.should be_empty
    end

    it 'is false when there are elements in the input' do
      QueueWithIndexes.new(&generator).should_not be_empty
    end

    it 'becomes true when it runs out of inputs' do
      queue = QueueWithIndexes.new(2, &generator)
      queue.take 2
      queue.should_not be_empty
      queue.take 1
      queue.should be_empty
    end
  end
end

require 'spec_helper'

describe Line do
  let(:_stderr)    { StringIO.new }
  let(:_stdout)    { StringIO.new }
  let(:_stdin)     { StringIO.new 100.times.map { |i| "line#{i.next}" }.join("\n") }
  let(:args)       { ['-l'] }
  let(:options)    { parse(args).update errstream: _stderr, outstream: _stdout, instream: _stdin }
  let(:stderr)     { exitstatus; _stderr.string }
  let(:stdout)     { exitstatus; _stdout.string }
  let(:exitstatus) { described_class.call options }

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
      args << '-2' << '^1..2'
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

require 'spec_helper'

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

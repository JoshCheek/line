require 'spec_helper'

matcher_interface = Class.new do
  Surrogate.endow self
  define(:matches?) { |line, positive_index, negative_index| true }
  define(:inspect)  { |parent=nil| }
end

describe 'matchers' do
  specify 'implement the matcher interface' do
    Line::Matchers::And.should             substitute_for matcher_interface, subset: true, names: true
    Line::Matchers::MatchEverything.should substitute_for matcher_interface, subset: true, names: true
    Line::Matchers::MatchNothing.should    substitute_for matcher_interface, subset: true, names: true
    Line::Matchers::Not.should             substitute_for matcher_interface, subset: true, names: true
    Line::Matchers::Or.should              substitute_for matcher_interface, subset: true, names: true
    Line::Matchers::Range.should           substitute_for matcher_interface, subset: true, names: true
  end

  specify "Range will raise an error if you somehow get it in a state we thought couldn't happen" do
    expect { Line::Matchers::Range.new(-2, -1).matches?('a', 1, nil) }
      .to raise_error /impossible/
  end
end

describe 'match_indexes (fucking helpers are too complex -.-)' do

  let(:spy) { matcher_interface.new }

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


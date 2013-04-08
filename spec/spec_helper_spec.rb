require 'spec_helper'

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


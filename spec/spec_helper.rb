require 'line'
require 'line/options_parser'
require 'surrogate/rspec'

module LineSpecHelpers
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

  def match_indexes(*indexes)
    MatchIndexes.new(true, *indexes)
  end

  def match_no_indexes(*indexes)
    MatchIndexes.new(false, *indexes)
  end

  alias match_index match_indexes
end


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

RSpec.configure do |config|
  config.include LineSpecHelpers
end

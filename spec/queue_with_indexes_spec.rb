require 'spec_helper'

describe Line::QueueWithIndexes do
  def generator
    values = ['a', 'b', 'c']
    lambda { values.shift || raise(StopIteration) }
  end

  it 'takes a function that generates values' do
    described_class.new(&generator).to_a.should == [['a', 0, nil], ['b', 1, nil], ['c', 2, nil]]
  end

  it 'stops reading from the generator once the input_generator raises StopIteration' do
    values = %w[a b c]
    queue = described_class.new do
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
    described_class.new(2, &generator).to_a.should == [['a', 0, nil], ['b', 1, -2], ['c', 2, -1]]
  end

  example 'when the size given is greater than the number of values, every value has a negative index' do
    described_class.new(4, &generator).to_a.should == [['a', 0, -3], ['b', 1, -2], ['c', 2, -1]]
  end

  it 'is cool with each being called all multiple times and such' do
    queue = described_class.new(2, &generator)
    queue.take(1).should == [['a', 0, nil]]
    queue.take(1).should == [['b', 1, -2]]
    queue.take(1).should == [['c', 2, -1]]
    queue.take(1).should == []
  end

  specify '#each returns the queue' do
    queue = described_class.new(&generator)
    queue.each {}.should equal queue
  end

  specify '#each is lazy' do
    described_class.new(&generator).each.map { 1 }.should == [1, 1, 1]
  end

  describe 'empty?' do
    it 'is true when there are no elements in the input' do
      described_class.new { raise StopIteration }.should be_empty
    end

    it 'is false when there are elements in the input' do
      described_class.new(&generator).should_not be_empty
    end

    it 'becomes true when it runs out of inputs' do
      queue = described_class.new(2, &generator)
      queue.take 2
      queue.should_not be_empty
      queue.take 1
      queue.should be_empty
    end
  end
end

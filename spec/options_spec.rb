require 'spec_helper'

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


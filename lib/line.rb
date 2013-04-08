require 'line/queue_with_indexes'

class Line
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

class Line
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
end

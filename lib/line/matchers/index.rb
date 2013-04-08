require 'line/matchers/helpers'

class Line
  module Matchers
    class Index
      include Helpers

      attr_accessor :index

      def initialize(index)
        self.index = index
      end

      def matches?(line, positive_index, negative_index)
        positive_index == index || negative_index == index
      end

      def inspect(parent=false)
        inspect_helper parent, index.to_s, false
      end
    end
  end
end

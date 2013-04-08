require 'line/matchers/helpers'

class Line
  module Matchers
    class Not
      include Helpers

      attr_accessor :matcher

      def initialize(matcher)
        self.matcher = matcher
      end

      def matches?(line, positive_index, negative_index)
        !matcher.matches?(line, positive_index, negative_index)
      end

      def inspect(parent=false)
        inspect_helper parent, "^#{matcher.inspect self}", true
      end
    end
  end
end

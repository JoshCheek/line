require 'line/matchers/helpers'

class Line
  module Matchers
    class Or
      include Helpers

      def initialize(matcher1, matcher2)
        @matcher1, @matcher2 = matcher1, matcher2
      end

      def matches?(line, positive_index, negative_index)
        @matcher1.matches?(line, positive_index, negative_index) ||
          @matcher2.matches?(line, positive_index, negative_index)
      end

      def inspect(parent=false)
        inspect_helper parent, "#{@matcher1.inspect self} || #{@matcher2.inspect self}", true
      end
    end
  end
end

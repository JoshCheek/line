require 'line/matchers/helpers'

class Line
  module Matchers
    class And
      include Helpers

      def initialize(matcher1, matcher2)
        @matcher1, @matcher2 = matcher1, matcher2
      end

      def matches?(*args)
        @matcher1.matches?(*args) && @matcher2.matches?(*args)
      end

      def inspect(parent=false)
        inspect_helper parent, "#{@matcher1.inspect self} && #{@matcher2.inspect self}", true
      end
    end
  end
end

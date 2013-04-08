require 'line/matchers/helpers'

class Line
  module Matchers
    class MatchNothing
      include Helpers

      def matches?(*)
        false
      end

      def inspect(parent=false)
        inspect_helper parent, "MatchNothing", false
      end
    end
  end
end

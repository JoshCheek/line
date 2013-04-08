require 'line/matchers/helpers'

class Line
  module Matchers
    class MatchEverything
      include Helpers

      def matches?(line, positive_index, negative_index)
        true
      end

      def inspect(parent=false)
        inspect_helper parent, "MatchEverything", false
      end
    end
  end
end

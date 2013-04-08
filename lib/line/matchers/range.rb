require 'line/matchers/helpers'

class Line
  module Matchers
    class Range
      include Helpers

      attr_accessor :lower, :upper

      def initialize(lower, upper)
        self.lower, self.upper = lower, upper
      end

      def matches?(line, positive_index, negative_index)
        if    negative_index && lower < 0 && upper < 0 then lower <= negative_index && negative_index <= upper
        elsif negative_index && lower < 0              then lower <= negative_index && positive_index <= upper
        elsif negative_index && upper < 0              then lower <= positive_index && negative_index <= upper
        elsif 0 < lower && 0 < upper                   then lower <= positive_index && positive_index <= upper
        elsif 0 < lower                                then lower <= positive_index
        elsif 0 < upper                                then positive_index <= upper
        else raise 'It was thought to be impossible for this to happen, please open an issue at https://github.com/JoshCheek/line with the arguments you invoked the program with'
        end
      end

      def inspect(parent=false)
        inspect_helper parent, "#{lower}..#{upper}", false
      end
    end
  end
end

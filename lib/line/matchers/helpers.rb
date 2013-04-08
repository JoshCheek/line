class Line
  module Matchers
    module Helpers
      def inspect_helper(parent, inspected, has_children)
        return inspected        if parent && parent.class == self.class
        return "(#{inspected})" if parent && has_children
        return inspected        if parent
        "Matcher(#{inspected})"
      end
    end
  end
end

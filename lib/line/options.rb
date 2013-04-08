class Line
  class Options
    attr_accessor :show_help, :strip, :force, :chomp, :indexes, :errors, :line_matcher, :line_numbers
    attr_accessor :instream, :outstream, :errstream, :help_screen, :buffer_size, :debug

    def initialize(attributes={})
      update attributes
      yield self if block_given?
    end

    def update(attributes)
      attributes.each { |attribute, value| __send__ "#{attribute}=", value }
      self
    end

    alias line_numbers? line_numbers
    alias show_help?    show_help
    alias debug?        debug
    alias strip?        strip
    alias force?        force
    alias chomp?        chomp

    def help_screen
      @help_screen ||= ''
    end

    def indexes
      @indexes ||= []
    end

    def errors
      @errors ||= {}
    end

    def instream
      @instream ||= $stdin
    end

    def outstream
      @outstream ||= $stdout
    end

    def errstream
      @errstream ||= $stderr
    end

    def buffer_size
      @buffer_size ||= 0
    end
  end
end

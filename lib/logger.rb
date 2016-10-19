module PubSub
  class Logger
    attr_reader :class_name

    def initialize(class_name)
      @class_name = class_name
    end

    def info(message)
      puts "#{class_name}: #{message}"
    end

    def error(message)
      warn "#{class_name}: #{message}"
    end
  end
end

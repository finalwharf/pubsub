module PubSub
  module Logger
    def info(message)
      puts message
    end

    def error(message)
      warn message
    end
  end
end

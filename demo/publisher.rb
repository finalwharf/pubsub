#!/usr/bin/env ruby

require_relative '../lib/publisher'
require 'readline'

def run(host, port)
  publisher = PubSub::Publisher.new
  return unless publisher.connect(host, port)

  puts "Enter a message ('q' or Ctrl-C to exit)."

  trap('SIGINT') do
    publisher.disconnect
    puts "\rExitting..."
    exit
  end

  while publisher.connected?

    user_input = Readline.readline('>> ', true)

    next  if user_input == ''
    break if user_input == 'q'

    partitioned = user_input.partition(' ')

    topic   = partitioned.first
    message = partitioned.last

    publisher.publish(topic, message)
  end

  publisher.disconnect
end

def usage
  warn 'Usage: '
  warn "  #{$PROGRAM_NAME} <port>"
end

if __FILE__ == $PROGRAM_NAME
  unless ARGV && ARGV.size == 1
    usage
    exit
  end

  host = '127.0.0.1'
  port = ARGV[0].to_i

  run(host, port)
end

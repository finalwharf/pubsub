#!/usr/bin/env ruby

require_relative '../lib/subscriber'

def run(host, port, topics)
  subscriber = PubSub::Subscriber.new
  return unless subscriber.connect(host, port)

  subscriber.subscribe(topics)

  puts "Type ^C to exit.\n"

  trap('SIGINT') do
    subscriber.disconnect
    puts "\rExitting..."
  end

  while subscriber.connected?
    data = subscriber.receive_message
    next unless data
    puts "##{data['topic']}: #{data['message']}"
  end
end

def usage
  warn 'Usage: '
  warn "  #{$PROGRAM_NAME} <port> <topic1[, topic2, topic3]>"
end

if __FILE__ == $PROGRAM_NAME
  unless ARGV && ARGV.size > 1
    usage
    exit
  end

  args = ARGV.clone

  # Use different intercafe/port
  host    = '127.0.0.1'
  port    = args.shift.to_i
  topics  = args

  run(host, port, topics)
end

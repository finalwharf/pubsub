#!/usr/bin/env ruby

require_relative '../lib/broker'

def run(host, port)
  broker = PubSub::Broker.new
  return unless broker.bind(host, port)

  puts "Type ^C to exit.\n"

  trap('SIGINT') do
    broker.stop
    puts "\rExitting..."
  end

  broker.start
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
  port = ARGV.shift.to_i

  run(host, port)
end

#!/usr/bin/env ruby

require_relative 'logger'
require 'socket'
require 'json'

module PubSub
  class Subscriber
    include Logger

    attr_accessor :socket

    DEFAULT_HOST = '0.0.0.0'.freeze
    DEFAULT_PORT = 12345

    # Connect to the PubSub broker on given host and port.
    # Returns true or false depending on connection success.
    def connect(host = DEFAULT_HOST, port = DEFAULT_PORT)
      self.socket = TCPSocket.open(host, port)

      identify

      remote_host = socket.peeraddr[3]
      remote_port = socket.peeraddr[1]

      info "PubSub Subscriber connected to #{remote_host}:#{remote_port}."
      return true
    rescue Errno::ECONNREFUSED
      error 'Connection refused! Is the Broker running?'
      return false
    end

    def connected?
      !socket.closed?
    end

    def disconnect
      socket.close
    end

    def receive_message
      data = socket_read_blocking
      JSON.parse(data.strip) if data
    rescue JSON::ParserError
      error 'Invalid message format.'
    end

    # Tell the broker we are a subscriber
    def identify
      socket_write(client_type: 'subscriber')
    end

    def subscribe(topics)
      socket_write(topics: topics)
    end

    def socket_read_blocking
      socket.gets
    rescue
      disconnect
    end

    def socket_write(data)
      socket.puts(JSON.dump(data))
    rescue
      error 'Connection lost! Exitting...'
      disconnect
    end
  end
end

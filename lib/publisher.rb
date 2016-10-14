#!/usr/bin/env ruby

require_relative 'logger'
require 'socket'
require 'json'

module PubSub
  class Publisher
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

      info "PubSub Publisher connected to #{remote_host}:#{remote_port}."
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

    def identify
      socket_write(client_type: 'publisher')
    end

    def publish(topic, message)
      socket_write(
        topic:    topic,
        message:  message
      )
    end

    def socket_write(payload)
      socket.puts(JSON.dump(payload))
    rescue
      error 'Connection lost! Exitting...'
      socket.close
    end
  end
end

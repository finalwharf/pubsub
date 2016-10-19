#!/usr/bin/env ruby

require_relative 'logger'
require 'socket'
require 'json'

module PubSub
  class Publisher
    attr_accessor :socket
    attr_reader   :logger

    DEFAULT_HOST = '0.0.0.0'.freeze
    DEFAULT_PORT = 12345

    def initialize
      @logger = Logger.new(self.class.name)
    end

    # Connect to the PubSub broker on given host and port.
    # Returns true or false depending on connection success.
    def connect(host = DEFAULT_HOST, port = DEFAULT_PORT)
      self.socket = create_socket(host, port)

      identify

      remote_host = socket.peeraddr[3]
      remote_port = socket.peeraddr[1]

      logger.info("Connected to #{remote_host}:#{remote_port}.")
      return true
    rescue Errno::ECONNREFUSED
      logger.error('Connection refused! Is the Broker running?')
      return false
    end

    def create_socket(host, port)
      TCPSocket.new(host, port)
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
      logger.error('Connection lost! Exiting...')
      socket.close
    end
  end
end

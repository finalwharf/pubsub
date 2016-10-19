#!/usr/bin/env ruby

require_relative 'logger'
require 'socket'
require 'json'

module PubSub
  # A simple PubSub broker. It is responsible for receiving
  # messages from publishers and forwarding them to subscribers.
  #
  # rubocop:disable ClassLength
  class Broker
    attr_accessor :publishers, :topic_subscribers
    attr_accessor :socket, :readable_sockets
    attr_reader   :logger

    DEFAULT_HOST = '0.0.0.0'.freeze
    DEFAULT_PORT = 12345

    def initialize
      @readable_sockets = []
      @publishers = []
      @topic_subscribers = {}

      @logger = Logger.new(self.class.name)
    end

    # Create the TCP server for the broker.
    # Returns true or false depending on connection success.
    def bind(host = DEFAULT_HOST, port = DEFAULT_PORT)
      self.socket = create_server(host, port)
      @readable_sockets << socket

      logger.info("PubSub Broker started on port #{socket.addr[1]}...")
      return true
    rescue Errno::EADDRINUSE
      logger.error('Specified address and port are already in use.')
      return false
    end

    def create_server(host, port)
      TCPServer.new(host, port)
    end

    def start
      until socket.closed?
        available_for_read = read_blocking

        available_for_read.each do |io|
          if io == socket
            # Someone's trying to connect
            handle_client_connection
          elsif publishers.include?(io)
            # Someone's trying to publish a message
            handle_published_message(io)
          end
        end
      end
    end

    def stop
      socket.close
    end

    def read_blocking
      readable = IO.select(readable_sockets)
      readable.first
    rescue Errno::EBADF
      # Not interested in EBADF if we are closing the socket
      raise unless socket.closed?

      return []
    end

    # Handle incoming connections
    def handle_client_connection
      client = socket.accept

      client_type = determine_client_type(client)
      logger.info("Client connected. Client type is #{client_type}")

      if client_type == 'publisher'
        handle_publisher_connection(client)
      elsif client_type == 'subscriber'
        handle_subscriber_connection(client)
      end
    end

    def determine_client_type(client)
      # Prevent clients from blocking the broker with idle connections
      # Close the socket if the client doesn't identify within a second
      unless client_ready_for_read?(client)
        logger.info('Client is not identifying. Closing connection.')
        client.close
        return nil
      end

      data = socket_read(client)
      data.is_a?(Hash) ? data['client_type'] : nil
    end

    def client_ready_for_read?(client)
      IO.select([client], nil, nil, 1)
    end

    def handle_publisher_connection(client)
      readable_sockets  << client
      publishers        << client
    end

    def handle_subscriber_connection(client)
      data = socket_read(client)

      unless data
        client.close
        return
      end

      data['topics'].each do |topic|
        topic_subscribers[topic] = [] unless topic_subscribers.key?(topic)
        topic_subscribers[topic] << client
      end
    end

    # Receive a message from a publisher and distribute it to
    # all subscribers interested in the topic in question
    def handle_published_message(publisher)
      data = socket_read(publisher)

      return unless data.is_a?(Hash) && topic_subscribers.key?(data['topic'])

      topic = data['topic']

      topic_subscribers[topic].each do |subscriber|
        socket_write(subscriber, data)
      end
    end

    def socket_read(socket)
      data = socket.gets
      JSON.parse(data.strip) if data
    rescue JSON::ParserError
      logger.error('Invalid message format.')
    end

    def socket_write(socket, payload)
      socket.puts(JSON.dump(payload))
    rescue
      logger.error('Connection lost! Disconnecting client...')

      topic_subscribers.each do |_topic, subscribers|
        subscribers.delete(socket)
        socket.close
      end
    end
  end
end

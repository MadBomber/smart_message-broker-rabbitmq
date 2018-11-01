# smart_message/broker/rabbitmq.rb
# encoding: utf-8
# frozen_string_literal: true

# NOTE: RabbitMQ is a very powerful broker with many configurable
#       architectures.  This initial implementation of the broker
#       makes some trade-offs for consistency over configurability.

# NOTE: routing keys ...
#       The AMQP 0.9.1 specification says that topic segments (words)
#       may contain the letters A-Z and a-z and digits 0-9.

# NOTE: One of the problems with the ActiveRecord architecture model is
#       that it abstracts the lowest common functionality of the back-end
#       RDBMS systems.  The same will be true for this broker architecture
#       in that the different capabilities of each broker must be broken
#       down to a simple sub-set.  Any functionality outside of this common
#       capability will require a specialized implementation.

# NOTE: The common functionality must be limited to #publish, #subscribe and
#       #unscubscribe methods of the smart message.  The unique capabilities
#       of RabbitMQ's connection, channel, exchange and queue concepts with the
#       message routing key must be hidden behind the three amigos.


# TODO: RabbutNQ/Bunny requires a MIME type to be associated with the payload.
#       This directly relates to which serializer is used with the SmartMessage.

require "bunny"
require 'nenv'

require "smart_message/broker/rabbitmq/version"

module SmartMessage::Broker
  # Use the RabbitMQ AMQP broker
  class Rabbitmq < SmartMessage::Broker::Base

    DEFAULT_OPTIONS = {
      rabbitmq_url: Nenv.rabbitmq_url || 'amqp://guest:guest@localhost:5672',
      loopback:     false,
      connection:   nil,
      channel:      nil,
      exchange:     nil,
    }

    # Initialize
    # setting loopback to true will force a published message through
    # the receive process
    def initialize(options: ())
      @options = DEFAULT_OPTIONS.merge(options)

      if connection.nil?
        @options[:connection] = Bunny.new(@options[:rabbitmq_url])
        connection.start

        @options[:channel]    = connection.create_channel

        # REMEMBER: connection.exchange_exists?("SmartMessage")
        @options[:exchange]   = channel.topic("SmartMessage", auto_delete: false)

        channel.queue(
          "default",
          durable:      true,
          auto_delete:  false
        ).bind(
          exchange,
          routing_key: "SmartMessage.#"
        ).subscribe do |delivery_info, metadata, payload|
          puts "A generic SmartMessage with routing key: #{delivery_info.routing_key}"
          puts "Payload: #{payload}"
        end
      end # if connection.nil?

      super
    end


    # build some accessor methods to the options hash
    # SNELL: maybe it would be better to use `attr_accessor`
    #        maybe these should be private methods.
    [:connection, :channel, :exchange].each do |method_name|
      define_method(method_name) { @options[method_name] }
    end


    # loopback is a boolean that controls whether all published
    # messages are looped back into the system via the
    # subscription management framework.
    def loopback?
      @options[:loopback]
    end


    def loopback=(a_boolean)
      @options[:loopback] = a_boolean
    end


    # Is there anything about this broker that needs to be configured
    # TOdO:  RabbitMQ/Bunny has lots of ways to configure a broker.  This
    #        method may be more complex than what is currently in the initialize
    #        method.
    def self.config
      debug_me{'@options'}
    end


    # put the encoded_message into the delievery system
    # TODO: the message_header must have something from which the
    #       message MIME Type can be calculated.  Maybe this is
    #       something that has to be initialized by the chosen Serializer
    def publish(message_header, message_payload)
      # NOTE: The routing key can only be alpha-numeric with periods.
      routing_key = message_header.message_class.
                      gsub('::', '.').          # allocates namespace to heirarchie
                      gsub(/[^a-z0-9]/i, '.')   # removes stuff that is not AMQP allowed

      # SMELL: Mayme this check/creation event should be done
      #        at the time that the message class is elaborated?
      unless connectuib.queue_exists?(routing_key)
        channel.queue(
          routing_key,
          durable:      true,
          auto_delete:  false
        ).bind(
          exchange,
          routing_key: routing_key
        )
      end

      exchange.publish(
        message_payload,
        routing_key: routing_key
      )

      receive(message_header, message_payload) if loopback?
    end


    def receive(message_header, message_payload)
      debug_me(file: @file){[ :message_header, :message_payload ]}

      @@dispatcher.route(message_header, message_payload)
    end


    # Add a non-duplicated message_class to the subscriptions Array
    def subscribe(message_class, process_method)
      #
      @@dispatcher.add(message_class, process_method)
    end


    # remove a message_class and its process_method
    def unsubscribe(message_class, process_method)
      @@dispatcher.drop(message_class, process_method)
    end


    # remove a message_class and all of its process_methods
    def unsubscribe!(message_class, process_method)
      @@dispatcher.drop_all(message_class)
    end
  end # class Rabbitmq < SmartMessage::Broker::Base
end # module SmartMessage::Broker

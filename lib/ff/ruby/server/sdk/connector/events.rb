require "json"
require "sse-client"

require_relative './service'

class Events < Service

  def initialize(

    url,
    headers,
    updater
  )

    if @updater != nil

      unless @updater.kind_of?(Updater)

        raise "The 'callback' parameter must be of '" + Updater.to_s + "' data type"
      end
    end

    @updater = updater

    @sse = SSE::EventSource.new(

      url = url,
      query = {},
      headers = headers
    )

    @sse.open do

      on_open
    end

    @sse.error do |error|

      if error != nil

        puts "SSE ERROR: " + error.body
      end

      on_error
    end

    @sse.message do |message|

      on_message(message)
    end

    @updater.on_ready
  end

  def start

    puts "Starting EventSource service"
    @sse.start
  end

  def stop

    puts "Stopping EventSource service"

    # TODO: This method is private !?
    # @sse.stop

    on_closed
  end

  def close

    stop
  end

  def on_open

    puts "EventSource connected"
    @updater.on_connected
  end

  def on_error

    puts "EventSource error"
    @updater.on_error

    stop
  end

  def on_closed

    puts "EventSource disconnected"
    @updater.on_disconnected
  end

  def on_message(message)

    puts "EventSource message received " + message.to_s

    msg = JSON.parse(message)
    @updater.update(msg)
  end
end
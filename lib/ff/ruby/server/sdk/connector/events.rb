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

    @sse = EventSource.new(

      url = url,
      headers = headers
    )

    @sse.open(

      self.method(:on_open)
    )

    @sse.error(

      self.method(:on_error)
    )

    @sse.message(

      self.method(:on_message)
    )

    @updater.on_ready
  end

  def start

    puts "Starting EventSource service"
    @sse.start
  end

  def stop

    puts "Stopping EventSource service"
    @sse.stop

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
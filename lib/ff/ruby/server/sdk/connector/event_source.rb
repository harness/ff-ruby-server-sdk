require "sse-client"

require_relative './service'

class EventSource < Service

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

    @sse = EventSource(

      url = url,
      headers = headers,
      query = {}
    )

    @sse.open(

      self.method(:on_open)
    )

    @sse.error(

      self.method(:on_closed)
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
  end

  def close

    stop
  end

  def on_open

    puts "EventSource connected"
    @updater.on_connected
  end

  def on_closed

    puts "EventSource disconnected"
    @updater.on_disconnected
  end

  def on_message

    # TODO
  end
end
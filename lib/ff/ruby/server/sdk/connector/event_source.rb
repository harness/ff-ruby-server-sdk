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


    )

    @sse.error(


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
end
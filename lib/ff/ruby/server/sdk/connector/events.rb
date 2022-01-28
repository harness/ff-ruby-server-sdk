require "json"
require "sse-client"

require_relative './service'

class Events < Service

  def initialize(

    url,
    headers,
    updater,
    logger = nil
  )

    if @updater != nil

      unless @updater.kind_of?(Updater)

        raise "The 'callback' parameter must be of '" + Updater.to_s + "' data type"
      end
    end

    @updater = updater

    if logger != nil

      @logger = logger
    else

      @logger = Logger.new(STDOUT)
    end

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

        @logger.error "SSE ERROR: " + error.body
      end

      on_error
    end

    @sse.message do |message|

      on_message(message)
    end

    @sse.on("*") do |message|

      on_message(message)
    end

    @updater.on_ready
  end

  def start

    @logger.info "Starting EventSource service"

    @sse.start
  end

  def stop

    @logger.info "Stopping EventSource service"

    on_closed
  end

  def close

    stop
  end

  def on_open

    @logger.info "EventSource connected"

    @updater.on_connected
  end

  def on_error

    @logger.error "EventSource error"

    @updater.on_error

    stop
  end

  def on_closed

    @logger.info "EventSource disconnected"

    @updater.on_disconnected
  end

  def on_message(message)

    @logger.debug "EventSource message received " + message.to_s

    msg = JSON.parse(message)
    @updater.update(msg)
  end
end
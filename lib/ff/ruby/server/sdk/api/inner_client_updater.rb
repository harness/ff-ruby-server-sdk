require "logger"

require_relative "../connector/updater"

class InnerClientUpdater < Updater

  def initialize(

    poll_processor,
    client_callback,
    logger = nil
  )

    unless poll_processor.kind_of?(PollingProcessor)

      raise "The 'poll_processor' parameter must be of '" + PollingProcessor.to_s + "' data type"
    end

    unless client_callback.kind_of?(ClientCallback)

      raise "The 'client_callback' parameter must be of '" + ClientCallback.to_s + "' data type"
    end

    if logger != nil

      @logger = logger
    else

      @logger = Logger.new(STDOUT)
    end

    @poll_processor = poll_processor
    @client_callback = client_callback
  end

  def on_connected

    @poll_processor.stop
  end

  def on_disconnected

    unless @client_callback.is_closing

      @poll_processor.start
    end
  end

  def on_ready

    @client_callback.on_update_processor_ready()
  end

  def on_error

    @logger.error "Error occurred"
  end

  def update(message)

    @client_callback.update(message, false)
  end
end
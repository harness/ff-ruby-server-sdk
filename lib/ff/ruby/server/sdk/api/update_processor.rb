require "concurrent-ruby"

require_relative "../common/closeable"

class UpdateProcessor < Closeable

  def init(

    connector,
    repository,
    callback,
    logger
  )

    @connector = connector
    @repository = repository
    @updater = callback
    @executor = Concurrent::FixedThreadPool.new(100)

    if logger != nil

      @logger = logger
    else

      @logger = Logger.new(STDOUT)
    end
  end

  def start

    @logger.debug "Starting updater (EventSource)"

    if @updater != nil

      unless @updater.kind_of?(Updater)

        raise "The 'callback' parameter must be of '" + Updater.to_s + "' data type"
      end
    end

    if @connector != nil

      unless @connector.kind_of?(Connector)

        raise "The 'connector' must be of '" + Connector.to_s + "' data type"
      end

      @executor.post do

        @stream = @connector.stream(@updater)
        @stream.start
      end
    end
  end

  def stop

    @logger.info "Stopping updater (EventSource)"

    if @stream != nil

      @stream.stop
    end

    @executor.shutdown
    @executor.wait_for_termination(3)

    if @executor.shuttingdown?

      @executor.kill
    end

    @logger.info "Updater stopped (EventSource)"
  end

  def close

    @logger.info "Closing UpdateProcessor"

    stop
  end

  def update(message)

    if message["domain"] == "flag"

      @executor.post do

        process_flag(message)
      end

      return
    end

    if message["domain"] == "target-segment"

      @executor.post do

        process_segment(message)
      end
    end
  end

  protected

  def process_flag(message)

    config = @connector.get_flag(message["identifier"])

    if config != nil

      if message["event"] == "create" || message["event"] == "patch"

        @repository.set_flag(message["identifier"], config)

      else

        if message["event"] == "delete"

          @repository.delete_flag(message["identifier"])
        end
      end
    end
  end

  def process_segment(message)

    @logger.info "Processing segment message: " + message.to_s

    segment = @connector.get_segment(message["identifier"])

    if segment != nil

      if message["event"] == "create" || message["event"] == "patch"

        @repository.set_segment(message.identifier, segment)

      else

        if message["event"] == "delete"

          @repository.delete_segment(message["identifier"])
        end
      end
    end
  end
end
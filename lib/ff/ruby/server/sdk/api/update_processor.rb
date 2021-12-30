require_relative "../common/closeable"

class UpdateProcessor < Closeable

  def initialize(

    connector,
    repository,
    callback
  )

    @connector = connector
    @repository = repository
    @updater = callback
  end

  def start

    puts "Starting updater (EventSource)"

    if @updater != nil

      unless @updater.kind_of?(Updater)

        raise "The 'callback' parameter must be of '" + Updater.to_s + "' data type"
      end
    end

    if @connector != nil

      unless @connector.kind_of?(Connector)

        raise "The 'connector' must be of '" + Connector.to_s + "' data type"
      end

      @stream = @connector.stream(@updater)
      @stream.start
    end
  end

  def stop

    if @stream != nil

      @stream.stop
    end

    # TODO: Shutdown the executor
  end

  def update(message)

  end

  protected

  def process_flag(message)

    nil
  end

  def process_segment(message)

    nil
  end

  public def close

    puts "Closing UpdateProcessor"

    stop

    if @stream != nil

      unless @stream.kind_of?(Closeable)

        raise "The 'stream' must be of '" + Closeable.to_s + "' data type"
      end

      @stream.close
    end
  end
end
require "concurrent-ruby"

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
    @executor = Concurrent::FixedThreadPool.new(100)
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

    puts "Stopping updater (EventSource)"

    if @stream != nil

      @stream.stop
    end

    @executor.shutdown
    @executor.wait_for_termination
  end

  def close

    puts "Closing UpdateProcessor"

    stop
  end

  def update(message)

    if message.domain == "flag"

      @executor.post do

        process_flag(message)
      end

      return
    end

    if message.domain == "target-segment"

      @executor.post do

        process_segment(message)
      end
    end
  end

  protected

  def process_flag(message)

    config = @connector.get_flag(message.identifier)

    if config != nil

      if message.event == "create" || message.event == "patch"

        @repository.set_flag(message.identifier, config)
      else
        if message.event == "delete"

          @repository.delete_flag(message.identifier)
        end
      end
    end

  end

  def process_segment(message)

    segment = @connector.get_segment(message.identifier)

    if segment != nil

      if message.event == "create" || message.event == "patch"

        @repository.set_segment(message.identifier, segment)
      else
        if message.event == "delete"

          @repository.delete_segment(message.identifier)
        end
      end
    end
  end
end
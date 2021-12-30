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

  end

  def stop

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
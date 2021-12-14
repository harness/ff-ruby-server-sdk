require_relative "../common/closeable"

class PollingProcessor < Closeable

  def initialize(

    connector,
    repository,
    poll_interval_in_sec,
    callback
  )

    @connector = connector
    @repository = repository
    @poll_interval_in_sec = poll_interval_in_sec
    @callback = callback
  end

  def retrieve_flags

    # TODO:
    puts "To be implemented"
    []
  end

  def retrieve_segments

    # TODO:
    puts "To be implemented"
    []
  end

  def start

  end

  def stop

  end

  def close

    stop
    puts "Closing PollingProcessor"
  end

end
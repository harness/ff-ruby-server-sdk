require_relative "../common/closeable"

class PollingProcessor < Closeable

  def initialize(

    connector,
    repository,
    poll_interval_in_sec,
    callback
  )

    @callback = callback
    @connector = connector
    @repository = repository
    @poll_interval_in_sec = poll_interval_in_sec
  end

  def retrieve_flags

    flags = []

    puts "Fetching flags started"

    result = @connector.get_flags

    if result != nil

      puts "Flags are fetched"

      result.each { |fc|

        if fc != nil

          @repository.set_flag(fc.feature, fc)
          flags.push(fc)
        end
      }
    end

    puts "Fetching flags finished"

    flags
  end

  def retrieve_segments

    segments = []

    puts "Fetching segments started"

    result = @connector.get_segments

    if result != nil

      puts "Segments are fetched"

      result.each { |s|

        if s != nil

          @repository.set_flag(s.identifier, s)
          flags.push(s)
        end
      }
    end

    puts "Fetching segments finished"

    segments
  end

  def start_async

    puts "Async starting: " + self.to_s

    @ready = true

    @thread = Thread.new do

      puts "Async started: " + self.to_s

      while @ready do

        puts "Async poll iteration"

        if @callback != nil

          @callback.on_poller_iteration(self)
        end

        begin

          retrieve_flags
          retrieve_segments

          unless @initialized

            @initialized = true
            puts "PollingProcessor initialized"

            if @callback != nil

              @callback.on_poller_ready(self)
            end
          end

        rescue OpenapiClient::ApiError => e

          if @callback != nil

            @callback.on_poller_error(e)
          end
        end

        sleep(@poll_interval_in_sec)
      end
    end

    @thread.run
  end

  def stop_async

    @ready = false
    @initialized = false
  end

  def start

    puts "Starting PollingProcessor with request interval: " + @poll_interval_in_sec.to_s
    start_async
  end

  def stop

    puts "Stopping PollingProcessor"
    stop_async
    unless @ready

      puts "PollingProcessor stopped"
    end
  end

  def close

    stop
    puts "Closing PollingProcessor"
  end

  def is_ready

    @ready && @initialized
  end
end
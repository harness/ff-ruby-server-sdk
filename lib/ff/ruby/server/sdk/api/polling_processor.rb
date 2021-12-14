require_relative "../common/closeable"
require_relative "../connector/connector_exception"

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

    flags = []

    begin

      puts "Fetching flags started"

      @connector
        .get_flags
        .each { |fc|

          if fc != nil

            @repository.set_flag(fc.feature, fc)
            flags.push(fc)
          end
        }

      puts "Fetching flags finished"

    rescue :ConnectorException => e

      puts "ERROR - Start\n\n" + e.to_s + "\nERROR - End"
    end

    flags
  end

  def retrieve_segments

    segments = []

    begin

      puts "Fetching segments started"

      @connector
        .get_segments
        .each { |s|

          if s != nil

            @repository.set_flag(s.identifier, s)
            flags.push(s)
          end
        }

      puts "Fetching segments finished"

    rescue :ConnectorException => e

      puts "ERROR - Start\n\n" + e.to_s + "\nERROR - End"
    end

    segments
  end

  def start_async

    puts "Async starting: " + self.to_s

    @ready = true

    @thread = Thread.new do

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

    puts "Async started: " + self.to_s

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
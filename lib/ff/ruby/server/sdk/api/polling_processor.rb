require_relative "../common/closeable"

class PollingProcessor < Closeable

  def init(

    connector,
    repository,
    poll_interval_in_sec,
    callback,
    logger = nil
  )

    @callback = callback
    @connector = connector
    @repository = repository
    @poll_interval_in_sec = poll_interval_in_sec

    if logger != nil

      @logger = logger
    else

      @logger = Logger.new(STDOUT)
    end
  end

  def retrieve_flags

    flags = []

    @logger.debug "Fetching flags started"

    result = @connector.get_flags

    if result != nil

      @logger.debug "Flags are fetched"

      result.each { |fc|

        if fc != nil

          @repository.set_flag(fc.feature, fc)
          flags.push(fc)
        end
      }
    end

    @logger.debug "Fetching flags finished"

    flags
  end

  def retrieve_segments

    segments = []

    @logger.debug "Fetching segments started"

    result = @connector.get_segments

    if result != nil

      @logger.debug "Segments are fetched"

      result.each { |s|

        if s != nil

          @repository.set_segment(s.identifier, s)
          segments.push(s)
        end
      }
    end

    @logger.debug "Fetching segments finished"

    segments
  end

  def start_async

    @logger.debug "Async starting: " + self.to_s

    @ready = true

    @thread = Thread.new do

      @logger.debug "Async started: " + self.to_s

      while @ready do

        @logger.debug "Async poll iteration"

        if @callback != nil

          @callback.on_poller_iteration(self)
        end

        begin

          retrieve_flags
          retrieve_segments

          unless @initialized

            @initialized = true
            SdkCodes::info_poll_started(@logger, @poll_interval_in_sec)

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

    @logger.debug "Starting PollingProcessor with request interval: " + @poll_interval_in_sec.to_s
    start_async
  end

  def stop

    @logger.debug "Stopping PollingProcessor"
    stop_async
    unless @ready
      SdkCodes::info_polling_stopped @logger
    end
  end

  def close

    stop
    @logger.info "Closing PollingProcessor"
  end

  def is_ready

    @ready && @initialized
  end
end
require_relative "../common/closeable"

class AuthService < Closeable

  def initialize(connector = nil, poll_interval_in_sec = 60, callback = nil, logger = nil)

    unless connector.kind_of?(Connector)

      raise "The 'connector' parameter must be of '" + Connector.to_s + "' data type"
    end

    unless callback.kind_of?(ClientCallback)

      raise "The 'callback' parameter must be of '" + ClientCallback.to_s + "' data type"
    end

    @callback = callback
    @connector = connector
    @poll_interval_in_sec = poll_interval_in_sec

    if logger != nil

      @logger = logger
    else

      @logger = Logger.new(STDOUT)
    end
  end

  def start_async

    @logger.debug "Async starting: " + self.to_s

    @ready = true

    @thread = Thread.new do

      @logger.debug "Async started: " + self.to_s

      while @ready do

        @logger.debug "Async auth iteration"

        if @connector.authenticate

          @callback.on_auth_success
          stop_async
          @logger.info "Stopping Auth service"
        else

          @logger.error "Exception while authenticating, retry in " + @poll_interval_in_sec.to_s + " seconds"
        end

        sleep(@poll_interval_in_sec)
      end
    end

    @thread.run
  end

  def close

    stop_async
  end

  def on_auth_success

    unless @callback == nil

      unless @callback.kind_of?(ClientCallback)

        raise "Expected '" + ClientCallback.to_s + "' data type for the callback"
      end

      @callback.on_auth_success
    end
  end

  protected

  def stop_async

    @ready = false

    if @thread != nil

      @thread.exit
      @thread = nil
    end
  end
end
class AuthService

  def initialize(connector = nil, poll_interval_in_sec = 60, callback = nil)

    unless connector.kind_of?(Connector)

      raise "The 'connector' parameter must be of '" + Connector.to_s + "' data type"
    end

    unless callback.kind_of?(AuthCallback)

      raise "The 'callback' parameter must be of '" + AuthCallback.to_s + "' data type"
    end

    @callback = callback
    @connector = connector
    @poll_interval_in_sec = poll_interval_in_sec
  end

  def start_async

    puts "Async starting: " + self.to_s

    @ready = true

    @thread = Thread.new do

      while @ready do

        puts "Async iteration"

        if @connector.authenticate

          @callback.on_auth_success
          stop_async
          puts "Stopping Auth service"
        else

          puts "Exception while authenticating, retry in " + @poll_interval_in_sec.to_s + " seconds"
        end

        sleep(@poll_interval_in_sec)
      end
    end

    puts "Async started: " + self.to_s

    @thread.run
  end

  def close

    stop_async
  end

  def on_auth_success

    unless @callback == nil

      unless @callback.kind_of?(AuthCallback)

        raise "Expected '" + AuthCallback.to_s + "' data type for the callback"
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
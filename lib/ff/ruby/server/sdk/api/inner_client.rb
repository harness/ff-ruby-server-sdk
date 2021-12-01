require_relative "auth_service"
require_relative "auth_callback"
require_relative "../connector/harness_connector"

class InnerClient < AuthCallback

  def initialize(sdk_key = nil, config = nil, connector = nil)

    if sdk_key == nil || sdk_key.empty?

      raise "SDK key is not provided"
    end

    if config == nil

      @config = ConfigBuilder.new.build
    else

      unless config.kind_of?(Config)

        raise "The 'config' parameter must be of '" + Config.to_s + "' data type"
      end

      @config = config
    end

    if connector == nil

      @connector = HarnessConnector.new(sdk_key, config = @config, on_unauthorized = self)

    else

      unless connector.kind_of?(Connector)

        raise "The 'connector' parameter must be of '" + Connector.to_s + "' data type"
      end

      @connector = connector
    end

    @closing = false
    @failure = false
    @initialized = false
    @poller_ready = false
    @stream_ready = false
    @metric_ready = false

    setup
  end

  def on_auth_success

    puts "SDK successfully logged in"

    if @closing

      return
    end

    # run services only after token is processed

    # TODO: Start processors

  end

  def close

    puts "Closing the client: " + self.to_s

    @closing = true

    off

    # TODO: Close all

  end

  def off

    # TODO: Implement
  end

  protected

  def setup

    puts "SDK is not initialized yet! If store is used then values will be loaded from store \n" +
           " otherwise default values will be used in meantime. You can use waitForInitialization method for SDK" +
           " to be ready."

    @auth_service = AuthService.new(

      connector = @connector,
      poll_interval_in_sec = @config.poll_interval_in_seconds,
      callback = self
    )

    # TODO: Init. processors

    @auth_service.start_async
  end

  def on_unauthorized

    if @closing

      return
    end

    @auth_service.start_async

    # TODO: Stop processors

  end

end
class InnerClient

  def initialize(sdk_key = nil, config = nil, connector = nil)

    @closing = false

    if config == nil

      @config = ConfigBuilder.new.build
    else

      @config = config
    end

    if connector == nil

      # TODO: Connector init

    else

      @connector = connector
    end

    setup
  end

  def on_auth_success

    puts "SDK successfully logged in"

    if @closing

      return
    end

    # run services only after token is processed

  end

  protected

  def setup

    puts "SDK is not initialized yet! If store is used then values will be loaded from store \n" +
           " otherwise default values will be used in meantime. You can use waitForInitialization method for SDK" +
           " to be ready."

    unless @config.kind_of?(Config)

      raise "The 'config' parameter must be of '" + Config.to_s + "' data type"
    end

    @auth_service = AuthService.new(

      connector = @connector,
      poll_interval_in_sec = @config.poll_interval_in_seconds,
      callback = self
    )

    @auth_service.start_async
  end

end
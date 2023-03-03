
require_relative "../../generated/lib/openapi_client"
require_relative "../common/closeable"
require_relative "inner_client"

class CfClient < Closeable

  # Static:
  class << self

    @@instance = CfClient.new

    def instance

      @@instance
    end
  end

  # Static - End

  def initialize(api_key = nil, config = nil, connector = nil)

    if config == nil

      @config = ConfigBuilder.new.build
    else

      @config = config
    end

    @client = InnerClient.new(api_key, config, connector)

    @config.logger.debug "Client (1): " + @client.to_s
  end

  def init(api_key = nil, config = nil, connector = nil)

    if @client == nil

      @config = config

      @client = InnerClient.new(

        api_key = api_key,
        config = config,
        connector = connector
      )

      @config.logger.debug "Client (2): " + @client.to_s
    end
  end

  def wait_for_initialization

    if @client != nil

      @client.wait_for_initialization
    end
  end

  def bool_variation(identifier, target, default_value)

    @client.bool_variation(identifier, target, default_value)
  end

  def string_variation(identifier, target, default_value)

    @client.string_variation(identifier, target, default_value)
  end

  def number_variation(identifier, target, default_value)

    @client.number_variation(identifier, target, default_value)
  end

  def json_variation(identifier, target, default_value)

    @client.json_variation(identifier, target, default_value)
  end

  def destroy

    close
  end

  def close

    if @client != nil

      @client.close
    end
  end
end
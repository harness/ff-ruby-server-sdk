require 'singleton'
require_relative "../../generated/lib/openapi_client"
require_relative "../common/closeable"
require_relative "inner_client"

class CfClient < Closeable
  include Singleton

  def init(api_key: nil, config: nil, connector: nil)
    # Only initialize if @client is nil to avoid reinitialization
    unless @client
      @config = config || ConfigBuilder.new.build
      @client = InnerClient.new(api_key, @config, connector)
      @config.logger.debug "Client initialized with API key: #{api_key}"
    end
  end


  def wait_for_initialization(timeout_ms: nil)
    @client&.wait_for_initialization(timeout: timeout_ms)
  end

  def bool_variation(identifier:, target:, default_value:)
    @client.bool_variation(
      identifier: identifier,
      target: target,
      default_value: default_value
    )
  end

  def string_variation(identifier:, target:, default_value:)
    @client.string_variation(
      identifier: identifier,
      target: target,
      default_value: default_value
    )
  end

  def number_variation(identifier:, target:, default_value:)
    @client.number_variation(
      identifier: identifier,
      target: target,
      default_value: default_value
    )
  end

  def json_variation(identifier:, target:, default_value:)
    @client.json_variation(
      identifier: identifier,
      target: target,
      default_value: default_value
    )
  end
  def destroy
    close
  end

  def close
    @client&.close
    @client = nil
    @config = nil
  end
end

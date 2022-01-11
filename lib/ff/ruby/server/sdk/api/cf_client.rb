require "openapi_client"

require_relative "inner_client"
require_relative "../common/closeable"

class CfClient < Closeable

  # Static:
  class << self

    @@instance = CfClient.new

    def instance

      @@instance
    end
  end # Static - End

  def initialize(api_key = nil, config = nil, connector = nil)

    @client = InnerClient.new(api_key, config, connector)

    puts "Client (1): " + @client.to_s
  end

  def init(api_key = nil, config = nil, connector = nil)

    if @client == nil

      @client = InnerClient.new(api_key, config, connector)

      puts "Client (2): " + @client.to_s
    end
  end

  def wait_for_initialization

    if @client != nil

      @client.wait_for_initialization
    end
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
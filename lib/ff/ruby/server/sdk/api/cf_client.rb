require "openapi_client"

require_relative "inner_client"

class CfClient

  # Static:
  class << self

    @@instance = CfClient.new

    def instance

      @@instance
    end
  end # Static - End

  def initialize(api_key = nil, config = nil, connector = nil)

    @client = InnerClient.new(api_key, config, connector)
  end

  def init(api_key = nil, config = nil, connector = nil)

    if @client == nil

      @client = InnerClient.new(api_key)
    end
  end

  def hello

    puts "Hello from the FF Ruby Server SDK: " + self.to_s
  end
end
require "openapi_client"

class CfClient

  # Static:
  class << self

    @@instance = CfClient.new

    def instance

      @@instance
    end
  end # Static - End

  private_class_method :new

  def init(sdk_key)

    if @client == nil

      @client = InnerClient.new(sdk_key)
    end
  end

  def hello

    puts "Hello from the FF Ruby Server SDK: " + self.to_s
  end
end
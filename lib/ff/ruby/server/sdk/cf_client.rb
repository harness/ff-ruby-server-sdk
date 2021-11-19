require "openapi_client"

class CfClient

  # Static:
  class << self

    @@instance = CfClient.new

    def instance

      @@instance
    end
  end # Static - End

  def hello

    puts "Hello from the FF Ruby Server SDK: " + self.to_s # + ", target instance: " + OpenapiClient::Variation.new
  end
end
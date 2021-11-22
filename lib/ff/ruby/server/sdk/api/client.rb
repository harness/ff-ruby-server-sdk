class Client

  def initialize(sdk_key, config = nil)

    @inner_client = InnerClient.new(sdk_key, config)
  end

end
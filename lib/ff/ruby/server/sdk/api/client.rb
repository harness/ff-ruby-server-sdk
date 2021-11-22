class Client

  def initialize(sdk_key, config = nil)

    @inner_client = InnerClient.new(sdk_key, config)
  end

  def hello

    puts "Hello from the FF Ruby Server SDK: " + self.to_s
  end
end
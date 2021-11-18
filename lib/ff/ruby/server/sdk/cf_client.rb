class CfClient

  # Static:
  class << self

    @@instance = CfClient.new

    def instance

      @@instance
    end
  end # Static - End

  def hello

    puts "Hello from the client: " + self.to_s
  end
end
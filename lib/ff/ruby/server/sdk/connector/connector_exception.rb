class ConnectorException < StandardError

  attr_reader :message

  def initialize(msg = "")

    @message = msg
  end
end
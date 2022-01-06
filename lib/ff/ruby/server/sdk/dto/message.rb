class Message

  attr_accessor :event, :domain, :identifier, :version

  def initialize
    super

    @event = ""
    @domain = ""
    @identifier = ""
    @version = 0
  end
end
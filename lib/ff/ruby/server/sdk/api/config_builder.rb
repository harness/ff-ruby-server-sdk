require "config"

class ConfigBuilder

  def build

    @config
  end

  def initialize

    @config = Config.new
  end

  def config_url(config_url)

    @config.config_url = config_url
    self
  end

  def event_url(event_url)

    @config.event_url = event_url
    self
  end

end
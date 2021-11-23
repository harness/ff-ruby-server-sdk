class ConfigBuilder

  def build

    @config
  end

  def initialize

    @config = Config.new
  end

  def config_url(config_url)

    @config.config_url = config_url
  end
end
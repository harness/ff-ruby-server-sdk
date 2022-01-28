class ConfigBuilder

  def build

    @config
  end

  def initialize

    @config = Config.new
    @config.cache = DefaultCache.new(@config.logger)
  end

  def config_url(config_url)

    @config.config_url = config_url
    self
  end

  def event_url(event_url)

    @config.event_url = event_url
    self
  end

  def stream_enabled(stream_enabled)

    @config.stream_enabled = stream_enabled
    self
  end

  def poll_interval_in_seconds(poll_interval_in_seconds)

    @config.poll_interval_in_seconds = poll_interval_in_seconds
    self
  end

  def analytics_enabled(analytics_enabled)

    @config.analytics_enabled = analytics_enabled
    self
  end

  def frequency(frequency)

    @config.frequency = frequency
    self
  end

  def buffer_size(buffer_size)

    @config.buffer_size = buffer_size
    self
  end

  def all_attributes_private(all_attributes_private)

    @config.all_attributes_private = all_attributes_private
    self
  end

  def private_attributes(private_attributes)

    @config.private_attributes = private_attributes
    self
  end

  def connection_timeout(connection_timeout)

    @config.connection_timeout = connection_timeout
    self
  end

  def read_timeout(read_timeout)

    @config.read_timeout = read_timeout
    self
  end

  def write_timeout(write_timeout)

    @config.write_timeout = write_timeout
    self
  end

  def logger(logger)

    @config.logger = logger
    @config.cache.logger = logger
    self
  end

  def debugging(debug)

    @config.debugging = debug
    self
  end

  def metrics_service_acceptable_duration(metrics_service_acceptable_duration)

    @config.metrics_service_acceptable_duration = metrics_service_acceptable_duration
    self
  end

  def cache(cache)

    @config.cache = cache
    self
  end

  def store(store)

    @config.store = store
    self
  end
end
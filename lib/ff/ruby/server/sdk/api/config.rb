class Config

  # Static:
  class << self

    @@min_frequency = 60

    def min_frequency

      @@min_frequency
    end
  end # Static - End

  @config_url = "https://config.ff.harness.io/api/1.0"
  @event_url = "https://events.ff.harness.io/api/1.0"

  @stream_enabled = true

  @poll_interval_in_seconds = min_frequency

  @analytics_enabled = true

  @frequency = min_frequency

  @buffer_size = 1024

  @all_attributes_private = false

  @private_attributes = Set[]

  @connection_timeout = 10 * 1000

  @read_timeout = 30 * 1000

  @write_timeout = 10 * 1000

  @debug = false

  @metrics_service_acceptable_duration = 10 * 1000

  # TODO: Cache goes here
  @cache = nil

  # TODO: Storage goes here
  @store = nil

  def get_frequency

    [@frequency, @@min_frequency].max
  end

end
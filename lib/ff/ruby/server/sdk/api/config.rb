class Config

  # Static:
  class << self

    @@min_frequency = 60

    def min_frequency

      @@min_frequency
    end
  end # Static - End

  def initialize
    super

    @config_url = "https://config.ff.harness.io/api/1.0"
    @event_url = "https://events.ff.harness.io/api/1.0"

    @stream_enabled = true

    @poll_interval_in_seconds = @@min_frequency

    @analytics_enabled = true

    @frequency = @@min_frequency

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
  end

  def get_frequency

    [@frequency, @@min_frequency].max
  end

  def describe

    to_s + "\n" +
    "\tmin_frequency = " + @@min_frequency.to_s + "\n" +
           "\tconfig_url = " + @config_url + "\n" +
           "\tevent_url = " + @event_url + "\n" +
           "\tstream_enabled = " + @stream_enabled.to_s + "\n" +
           "\tpoll_interval_in_seconds = " + @poll_interval_in_seconds.to_s + "\n" +
           "\tanalytics_enabled = " + @analytics_enabled.to_s + "\n" +
           "\tfrequency = " + @frequency.to_s + "\n" +
           "\tget_frequency = " + get_frequency.to_s + "\n" +
           "\tbuffer_size = " + @buffer_size.to_s + "\n" +
           "\tall_attributes_private = " + @all_attributes_private.to_s + "\n" +
           "\tprivate_attributes = " + @private_attributes.to_s + "\n" +
           "\tconnection_timeout = " + @connection_timeout.to_s + "\n" +
           "\tread_timeout = " + @read_timeout.to_s + "\n" +
           "\twrite_timeout = " + @write_timeout.to_s + "\n" +
           "\tdebug = " + @debug.to_s + "\n" +
           "\tmetrics_service_acceptable_duration = " + @metrics_service_acceptable_duration.to_s + "\n" +
           "\tcache = " + @cache.to_s + "\n" +
           "\tstore = " + @store.to_s
  end
end
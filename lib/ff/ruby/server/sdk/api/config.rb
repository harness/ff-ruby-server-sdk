require "logger"

require_relative "default_cache"

class Config

  attr_accessor :config_url, :event_url, :stream_enabled, :poll_interval_in_seconds, :analytics_enabled,
                :frequency, :buffer_size, :all_attributes_private, :private_attributes, :connection_timeout,
                :read_timeout, :write_timeout, :debugging, :metrics_service_acceptable_duration, :cache, :store,
                :logger, :ssl_ca_cert

  # Static:
  class << self

    @@min_frequency = 60

    def min_frequency

      @@min_frequency
    end
  end
  # Static - End

  def initialize
    super

    @config_url = "https://config.ff.harness.io/api/1.0"
    @event_url = "https://events.ff.harness.io/api/1.0"

    @stream_enabled = true

    @poll_interval_in_seconds = @@min_frequency

    @analytics_enabled = true

    @frequency = @@min_frequency

    @buffer_size = 2048

    @all_attributes_private = false

    @private_attributes = Set[]

    @connection_timeout = 10 * 1000

    @read_timeout = 30 * 1000

    @write_timeout = 10 * 1000

    @debugging = false

    @logger = Logger.new(STDOUT)

    @metrics_service_acceptable_duration = 10 * 1000

    @cache = DefaultCache.new(@logger)

    # TODO: Storage goes here

    @store = nil
  end

  def get_frequency

    [@frequency, @@min_frequency].max
  end

  def verify_ssl_host

    true
  end

  def params_encoding

    nil
  end

  def timeout

    @connection_timeout
  end

  def verify_ssl

    true
  end

  def cert_file

    nil
  end

  def key_file

    nil
  end

  def ssl_ca_cert

    @ssl_ca_cert
  end

  def client_side_validation

    nil
  end

  def auth_settings

    {}
  end

  def base_url(args)

    @config_url
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
      "\tdebug = " + @debugging.to_s + "\n" +
      "\tmetrics_service_acceptable_duration = " + @metrics_service_acceptable_duration.to_s + "\n" +
      "\tcache = " + @cache.to_s + "\n" +
      "\tstore = " + @store.to_s
  end
end
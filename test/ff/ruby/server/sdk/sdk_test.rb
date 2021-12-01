# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ff/ruby/server/sdk"
require "minitest/autorun"

require_relative "wrapper"

class Ff::Ruby::Server::SdkTest < Minitest::Test

  def initialize(name)
    super

    @bool = false
    @number = 100
    @string = "test"
    @counter = 5
  end

  def test_version_number

    refute_nil ::Ff::Ruby::Server::Sdk::VERSION
  end

  def test_client_singleton_inst

    instance = CfClient.instance
    (0..@counter).each {

      compare_equal = CfClient.instance
      compare_not_equal = CfClient.new("test")

      refute_nil compare_equal
      refute_nil compare_not_equal

      assert_equal(instance, compare_equal)
      assert(instance != compare_not_equal)
    }
  end

  def test_client_constructor_inst

    test_string = "test"
    config = ConfigBuilder.new.build
    connector = HarnessConnector.new(test_string, config, nil)

    instance_with_no_config = CfClient.new(test_string)
    instance_with_config = CfClient.new(test_string, config)
    instance_with_connector = CfClient.new(test_string, config, connector)

    refute_nil instance_with_config
    refute_nil instance_with_connector
    refute_nil instance_with_no_config

    assert(instance_with_config != instance_with_no_config)
    assert(instance_with_connector != instance_with_no_config)
    assert(instance_with_connector != instance_with_config)
  end

  def test_config_constructor_inst

    config = Config.new
    config_not_equal = Config.new

    refute_nil config != nil
    refute_nil config_not_equal != nil

    assert(config != config_not_equal)
  end

  def test_config_properties

    config = Config.new

    assert_defaults(config)

    config.frequency = @number
    config.config_url = @string
    config.event_url = @string
    config.stream_enabled = @bool
    config.analytics_enabled = @bool
    config.all_attributes_private = !@bool
    config.private_attributes = Set[@string]
    config.connection_timeout = @number
    config.read_timeout = @number
    config.write_timeout = @number
    config.debugging = !@bool
    config.metrics_service_acceptable_duration = @number
    config.cache = DefaultCache.new

    assert_modified(config)
  end

  def test_config_builder

    builder = ConfigBuilder.new
    refute_nil builder

    config = builder.build
    assert_defaults(config)

    cache = DefaultCache.new

    config = ConfigBuilder.new
                          .event_url(@string)
                          .config_url(@string)
                          .stream_enabled(@bool)
                          .poll_interval_in_seconds(@number)
                          .analytics_enabled(@bool)
                          .frequency(@number)
                          .buffer_size(@number)
                          .all_attributes_private(!@bool)
                          .private_attributes(Set[@string])
                          .connection_timeout(@number)
                          .read_timeout(@number)
                          .write_timeout(@number)
                          .debugging(!@bool)
                          .metrics_service_acceptable_duration(@number)
                          .cache(cache)
                          .build

    assert_modified(config)
  end

  def test_lib_cache

    cache = DefaultCache.new

    refute_nil cache

    assert(cache.verify)

    refute_nil cache.keys

    (0..@counter).each do |i|

      cache.set("key_int_" + i.to_s, i)
      cache.set("key_str_" + i.to_s, i.to_s)
      cache.set("key_bool_" + i.to_s, i % 2 == 0)
    end

    (0..@counter).each do |i|

      value_int = cache.get("key_int_" + i.to_s)
      assert_equal(i, value_int)

      value_str = cache.get("key_str_" + i.to_s)
      assert_equal(i.to_s, value_str)

      value_bool = cache.get("key_bool_" + i.to_s)
      assert_equal(i % 2 == 0, value_bool)
    end

  end

  def test_client_destroy

    client = CfClient.instance

    refute_nil client

    client.destroy
  end

  def test_config_wrapping

    config = ConfigBuilder.new.build

    w1 = Wrapper.new(config)
    w2 = Wrapper.new(config)
    w3 = Wrapper.new(config.clone)

    w1.wrapped.config_url = "test1"
    w2.wrapped.config_url = "test2"
    w3.wrapped.config_url = "test3"

    assert(w1.wrapped.config_url == w2.wrapped.config_url)
    assert(w1.wrapped.config_url != w3.wrapped.config_url)
    assert(w2.wrapped.config_url != w3.wrapped.config_url)
  end

  private

  def assert_defaults(config)

    refute_nil config != nil

    assert(Config.min_frequency >= 0)
    assert(config.get_frequency == Config.min_frequency)
    assert(config.config_url == "https://config.ff.harness.io/api/1.0")
    assert(config.event_url == "https://events.ff.harness.io/api/1.0")
    assert(config.stream_enabled)
    assert(config.analytics_enabled)
    assert(config.frequency == Config.min_frequency)
    assert(!config.all_attributes_private)
    assert(config.private_attributes == Set[])
    assert(config.connection_timeout == 10 * 1000)
    assert(config.read_timeout == (Config.min_frequency * 1000) / 2)
    assert(config.write_timeout == config.connection_timeout)
    assert(!config.debugging)
    assert(config.metrics_service_acceptable_duration == config.connection_timeout)

    refute_nil config.cache
    assert(config.cache.verify)
  end

  def assert_modified(config)

    refute_nil config

    assert(config.get_frequency == @number)
    assert(config.config_url == @string)
    assert(config.event_url == @string)
    assert(!config.stream_enabled)
    assert(!config.analytics_enabled)
    assert(config.frequency == @number)
    assert(config.all_attributes_private)
    assert(config.private_attributes == Set[@string])
    assert(config.connection_timeout == @number)
    assert(config.read_timeout == @number)
    assert(config.write_timeout == @number)
    assert(config.debugging)
    assert(config.metrics_service_acceptable_duration == @number)

    refute_nil config.cache
    assert(config.cache.verify)
  end
end

# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "securerandom"
require "minitest/autorun"

require_relative "../../../../../lib/ff/ruby/server/sdk"

require_relative "wrapper"
require_relative "stub_connector"
require_relative "stub_evaluator"
require_relative "poller_test_callback"
require_relative "repository_test_callback"
require_relative "evaluator_integration_test"

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

    prefix = SecureRandom.uuid.to_s + "_"

    cache = DefaultCache.new

    refute_nil cache

    assert(cache.verify)

    refute_nil cache.keys

    (0..@counter).each do |i|

      cache.set(prefix + "key_int_" + i.to_s, i)
      cache.set(prefix + "key_str_" + i.to_s, i.to_s)
      cache.set(prefix + "key_bool_" + i.to_s, i % 2 == 0)
    end

    (0..@counter).each do |i|

      value_int = cache.get(prefix + "key_int_" + i.to_s)
      assert_equal(i, value_int)

      value_str = cache.get(prefix + "key_str_" + i.to_s)
      assert_equal(i.to_s, value_str)

      value_bool = cache.get(prefix + "key_bool_" + i.to_s)
      assert_equal(i % 2 == 0, value_bool)
    end

    (0..@counter).each do |i|

      cache.delete(prefix + "key_int_" + i.to_s)
      cache.delete(prefix + "key_str_" + i.to_s)
      cache.delete(prefix + "key_bool_" + i.to_s)
    end

    (0..@counter).each do |i|

      value_int = cache.get(prefix + "key_int_" + i.to_s)
      assert_nil(value_int)

      value_str = cache.get(prefix + "key_str_" + i.to_s)
      assert_nil(value_str)

      value_bool = cache.get(prefix + "key_bool_" + i.to_s)
      assert_nil(value_bool)
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

  def test_moneta_init

    store = FileMapStore.new
    refute_nil store

    config = ConfigBuilder.new
                          .store(store)
                          .build

    refute_nil config

    moneta = config.store
    refute_nil moneta

    prefix = SecureRandom.uuid.to_s

    (0..@counter).each do |i|

      key = prefix + i.to_s
      moneta.set(key, i)
      check = moneta.get(key)

      assert(i == check)
    end

    refute_nil moneta.keys

    assert(moneta.keys.size == @counter + 1)

    moneta.close

    assert(moneta.keys.size == 0)
  end

  def test_repository

    config = ConfigBuilder.new.build

    refute_nil config

    callback = RepositoryTestCallback.new

    repository = StorageRepository.new(config.cache, callback)

    assert_repository(repository, callback)

    file_map_store = FileMapStore.new

    refute_nil file_map_store

    config = ConfigBuilder.new.store(file_map_store).build

    refute_nil config

    callback = RepositoryTestCallback.new

    repository = StorageRepository.new(config.cache, callback, config.store)

    assert_repository(repository, callback)
  end

  def test_polling_processor

    config = ConfigBuilder.new.poll_interval_in_seconds(0.1).build

    refute_nil config

    callback = RepositoryTestCallback.new

    repository = StorageRepository.new(config.cache, callback)

    assert_repository(repository, callback)

    connector = StubConnector.new

    refute_nil connector

    callback = PollerTestCallback.new

    refute_nil callback

    processor = PollingProcessor.new(

      connector,
      repository,
      config.poll_interval_in_seconds,
      callback = callback
    )

    refute_nil processor

    processor.start

    sleep(1)

    assert_equal(1, callback.on_poller_ready_count)
    assert_equal(0, callback.on_poller_error_count)
    assert_equal(10, callback.on_poller_iteration_count)

    processor.close

    assert(!processor.is_ready)
  end

  def test_evaluator_murmur_hashing

    evaluator = StubEvaluator.new

    refute_nil evaluator

    {

      "test" => "test",
      "1" => "test",
      "test2" => "1",
      "12" => "1",
      "" => "1",
      "13" => "",
      "-" => "",
      "-2" => "-"

    }.each do |key, value|

      result = evaluator.get_normalized_number_exposed(key, value)
      assert result > 0
    end
  end

  def test_evaluator

    integration_test = EvaluatorIntegrationTest.new("Main_Evaluator_Integration_Test")

    assert integration_test.execute
  end

  def test_sized_queue

    count = 5
    queue = SizedQueue.new(5)

    (1..5).each do |x|

      queue.push(x)
    end

    assert queue.size == count

    all = []

    until queue.empty?

      item = queue.pop
      all.push(item)
    end

    assert queue.empty?
    assert all.size == count
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

  def assert_repository(repository, callback)

    refute_nil callback
    refute_nil repository

    assert(0, callback.on_flag_stored_count)
    assert(0, callback.on_flag_deleted_count)
    assert(0, callback.on_segment_stored_count)
    assert(0, callback.on_segment_deleted_count)

    flag_identifier = SecureRandom.uuid.to_s
    segment_identifier = SecureRandom.uuid.to_s

    flag = OpenapiClient::FeatureConfig.new
    segment = OpenapiClient::Segment.new

    flag.feature = flag_identifier
    segment.identifier = segment_identifier

    refute_nil flag
    refute_nil segment

    repository.set_flag(flag_identifier, flag)
    repository.set_segment(segment_identifier, segment)

    flag = repository.get_flag(flag_identifier)
    segment = repository.get_segment(segment_identifier)

    refute_nil flag
    refute_nil segment

    assert_equal(flag_identifier, flag.feature)
    assert_equal(segment_identifier, segment.identifier)

    repository.delete_flag(flag_identifier)
    repository.delete_segment(segment_identifier)

    repository.close

    flag = repository.get_flag(flag_identifier)
    segment = repository.get_segment(segment_identifier)

    assert_nil flag
    assert_nil segment

    assert_equal(1, callback.on_flag_stored_count)
    assert_equal(1, callback.on_flag_deleted_count)
    assert_equal(1, callback.on_segment_stored_count)
    assert_equal(1, callback.on_segment_deleted_count)
  end
end

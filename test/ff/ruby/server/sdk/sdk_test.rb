# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "securerandom"
require "minitest/autorun"

require "ff/ruby/server/sdk"

require_relative "wrapper"
require_relative "stub_connector"
require_relative "stub_evaluator"
require_relative "poller_test_callback"
require_relative "repository_test_callback"
require_relative "evaluator_integration_test"

class Ff::Ruby::Server::SdkTest < Minitest::Test

  def setup
    # Reset the Singleton instance before each test to ensure test isolation
    cf_client = CfClient.instance
    cf_client.instance_variable_set(:@client, nil)
    cf_client.instance_variable_set(:@config, nil)

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
    (0..@counter).each do
      compare_equal = CfClient.instance
      # Since CfClient.new is no longer valid, we should avoid using it.
      # Instead, ensure that calling instance.init multiple times does not create new clients.
      # Attempting to call CfClient.new should raise a NoMethodError.

      assert_equal(instance, compare_equal)
    end
  end

  def test_client_initialization
    config = ConfigBuilder.new.build
    connector = HarnessConnector.new(@string, config, nil)
    api_key = "test_api_key"

    client = CfClient.instance
    client.init(api_key: api_key, config: config, connector: connector)

    # Verify that @client is initialized and is an instance of InnerClient
    inner_client = client.instance_variable_get(:@client)
    refute_nil(inner_client, "InnerClient should be initialized")
    assert_instance_of(InnerClient, inner_client, "InnerClient should be an instance of InnerClient")
  end

  def test_client_reinitialization
    config1 = ConfigBuilder.new.build
    connector1 = HarnessConnector.new(@string, config1, nil)
    api_key1 = "api_key_1"

    client = CfClient.instance
    client.init(api_key: api_key1, config: config1, connector: connector1)

    # Capture the initial @client instance
    initial_inner_client = client.instance_variable_get(:@client)

    # Attempt to reinitialize with different parameters
    config2 = ConfigBuilder.new.build
    connector2 = HarnessConnector.new(@string, config2, nil)
    api_key2 = "api_key_2"

    client.init(api_key: api_key2, config: config2, connector: connector2)

    # Verify that the @client instance remains the same
    assert_same(initial_inner_client, client.instance_variable_get(:@client))
  end

  def test_client_methods
    config = ConfigBuilder.new.build
    connector = HarnessConnector.new(@string, config, nil)
    api_key = "test_api_key"

    client = CfClient.instance
    client.init(api_key: api_key, config: config, connector: connector)

    # Mock or stub @client methods if necessary
    inner_client = client.instance_variable_get(:@client)
    inner_client.stub :bool_variation, true do
      assert_equal(true, client.bool_variation(identifier: "identifier", target: "target", default_value: false))
    end

    inner_client.stub :string_variation, "variation" do
      assert_equal("variation", client.string_variation(identifier: "identifier", target: "target", default_value: "default"))
    end

    inner_client.stub :number_variation, 42 do
      assert_equal(42, client.number_variation(identifier: "identifier", target: "target", default_value: 0))
    end

    inner_client.stub :json_variation, { key: "value" } do
      assert_equal({ key: "value" }, client.json_variation(identifier: "identifier", target: "target", default_value: {}))
    end
  end

  def test_client_destroy
    config = ConfigBuilder.new.build
    connector = HarnessConnector.new(@string, config, nil)
    api_key = "test_api_key"

    client = CfClient.instance
    client.init(api_key: api_key, config: config, connector: connector)

    refute_nil client.instance_variable_get(:@client)

    client.destroy

    assert_nil(client.instance_variable_get(:@client))
    assert_nil(client.instance_variable_get(:@config))
  end

  def test_config_constructor_inst
    config = Config.new
    config_not_equal = Config.new

    refute_equal(config, nil)
    refute_equal(config_not_equal, nil)

    refute_equal(config, config_not_equal)
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
      cache.set(prefix + "key_bool_" + i.to_s, i.even?)
    end

    (0..@counter).each do |i|
      value_int = cache.get(prefix + "key_int_" + i.to_s)
      assert_equal(i, value_int)

      value_str = cache.get(prefix + "key_str_" + i.to_s)
      assert_equal(i.to_s, value_str)

      value_bool = cache.get(prefix + "key_bool_" + i.to_s)
      assert_equal(i.even?, value_bool)
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

  def test_config_wrapping
    config = ConfigBuilder.new.build

    w1 = Wrapper.new(config)
    w2 = Wrapper.new(config)
    w3 = Wrapper.new(config.clone)

    w1.wrapped.config_url = "test1"
    w2.wrapped.config_url = "test2"
    w3.wrapped.config_url = "test3"

    assert_equal("test2", w1.wrapped.config_url)
    assert_equal("test2", w2.wrapped.config_url)
    assert_equal("test3", w3.wrapped.config_url)

    refute_equal(w1.wrapped.config_url, w3.wrapped.config_url)
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

      assert_equal(i, check)
    end

    refute_nil moneta.keys
    assert_equal(@counter + 1, moneta.keys.size)

    moneta.close

    assert_equal(0, moneta.keys.size)
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

    processor = PollingProcessor.new
    processor.init(
      connector,
      repository,
      config.poll_interval_in_seconds,
      callback
    )

    refute_nil processor

    processor.start

    sleep(1) # Reduced sleep time for faster tests

    assert_equal(1, callback.on_poller_ready_count)
    assert_equal(0, callback.on_poller_error_count)
    assert(callback.on_poller_iteration_count >= 1)

    processor.close

    refute(processor.is_ready)
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
      assert(result > 0, "Hash for key=#{key}, value=#{value} should be positive")
    end
  end

  def test_evaluation_integration
    integration_test = EvaluatorIntegrationTest.new("Main_Evaluator_Integration_Test")
    integration_test.execute
  end

  def test_sized_queue
    count = 5
    queue = SizedQueue.new(5)

    (1..5).each do |x|
      queue.push(x)
    end

    assert_equal(count, queue.size)

    all = []

    until queue.empty?
      item = queue.pop
      all.push(item)
    end

    assert(queue.empty?)
    assert_equal(count, all.size)
  end

  private

  def assert_defaults(config)
    refute_nil(config)

    assert(Config.min_frequency >= 0)
    assert_equal(Config.min_frequency, config.get_frequency)
    assert_equal("https://config.ff.harness.io/api/1.0", config.config_url)
    assert_equal("https://events.ff.harness.io/api/1.0", config.event_url)
    assert(config.stream_enabled)
    assert(config.analytics_enabled)
    assert_equal(Config.min_frequency, config.frequency)
    refute(config.all_attributes_private)
    assert_equal(Set[], config.private_attributes)
    assert_equal(10_000, config.connection_timeout)
    assert_equal((Config.min_frequency * 1000) / 2, config.read_timeout)
    assert_equal(config.connection_timeout, config.write_timeout)
    refute(config.debugging)
    assert_equal(config.connection_timeout, config.metrics_service_acceptable_duration)

    refute_nil(config.cache)
    assert(config.cache.verify)
  end

  def assert_modified(config)
    refute_nil(config)

    assert_equal(@number, config.get_frequency)
    assert_equal(@string, config.config_url)
    assert_equal(@string, config.event_url)
    refute(config.stream_enabled)
    refute(config.analytics_enabled)
    assert_equal(@number, config.frequency)
    assert(config.all_attributes_private)
    assert_equal(Set[@string], config.private_attributes)
    assert_equal(@number, config.connection_timeout)
    assert_equal(@number, config.read_timeout)
    assert_equal(@number, config.write_timeout)
    assert(config.debugging)
    assert_equal(@number, config.metrics_service_acceptable_duration)

    refute_nil(config.cache)
    assert(config.cache.verify)
  end

  def assert_repository(repository, callback)
    refute_nil(callback)
    refute_nil(repository)

    assert_equal(0, callback.on_flag_stored_count)
    assert_equal(0, callback.on_flag_deleted_count)
    assert_equal(0, callback.on_segment_stored_count)
    assert_equal(0, callback.on_segment_deleted_count)

    flag_identifier = SecureRandom.uuid.to_s
    segment_identifier = SecureRandom.uuid.to_s

    flag = OpenapiClient::FeatureConfig.new
    segment = OpenapiClient::Segment.new

    flag.feature = flag_identifier
    segment.identifier = segment_identifier

    refute_nil(flag)
    refute_nil(segment)

    repository.set_flag(flag_identifier, flag)
    repository.set_segment(segment_identifier, segment)

    flag = repository.get_flag(flag_identifier)
    segment = repository.get_segment(segment_identifier)

    refute_nil(flag)
    refute_nil(segment)

    assert_equal(flag_identifier, flag.feature)
    assert_equal(segment_identifier, segment.identifier)

    repository.delete_flag(flag_identifier)
    repository.delete_segment(segment_identifier)

    repository.close

    flag = repository.get_flag(flag_identifier)
    segment = repository.get_segment(segment_identifier)

    assert_nil(flag)
    assert_nil(segment)

    assert_equal(1, callback.on_flag_stored_count)
    assert_equal(1, callback.on_flag_deleted_count)
    assert_equal(1, callback.on_segment_stored_count)
    assert_equal(1, callback.on_segment_deleted_count)
  end
end

require "minitest/autorun"
require "ff/ruby/server/sdk"
require "concurrent/atomics"

class FakeConfig
  attr_accessor :buffer_size, :logger

  def initialize(buffer_size: 10, logger: Logger.new(STDOUT))
    @buffer_size = buffer_size
    @logger = logger
  end

  def kind_of?(klass)
    klass == Config
  end

  def metrics_service_acceptable_duration
    10000
  end
end
class MetricsProcessorTest < Minitest::Test

  # Mock MetricsCallback to synchronize test execution
  class TestCallback < MetricsCallback
    def initialize
      @latch = Concurrent::CountDownLatch.new(1)
    end

    def on_metrics_ready
      @latch.count_down
    end

    def on_metrics_error(error)
      puts error
    end

    def wait_until_ready
      puts "Wait for metrics processor to start"
      @latch.wait(30)
    end
  end

  # Mock Connector to capture metrics without sending them
  class TestConnector < Connector
    attr_reader :captured_metrics

    def initialize
      @captured_metrics = []
      @post_metrics_latch = Concurrent::CountDownLatch.new(1)
    end

    def post_metrics(metrics)
      @captured_metrics.push(metrics)
      @post_metrics_latch.count_down
    end

    def get_flags
      print "get_flags"
      []
    end

    def get_segments
      print "get_segments"
      []
    end

    def wait_for_metrics(timeout = 30)
      puts "Waiting for metrics to be posted..."
      @post_metrics_latch.wait(timeout)
    end
  end

  def setup
    super

    # Initialize common objects used across tests
    @logger = Logger.new(STDOUT)
    @callback = TestCallback.new
    @connector = TestConnector.new

    # Initialize FakeConfig instead of Minitest::Mock
    @config = FakeConfig.new(buffer_size: 10, logger: @logger)

    # Initialize Targets, Features, and Variations
    @target = Target.new(identifier: "target-name", name: "target-id", attributes: {"location": "emea"})

    @variation1 = OpenapiClient::Variation.new
    @variation1.identifier = "variation1"
    @variation1.value = "on"
    @variation1.name = "Test"

    @variation2 = OpenapiClient::Variation.new
    @variation2.identifier = "variation2"
    @variation2.value = "off"
    @variation2.name = "Test"

    @feature1 = OpenapiClient::FeatureConfig.new
    @feature1.feature = "feature-name"
    @feature1.variations = [@variation1, @variation2]

    @feature2 = OpenapiClient::FeatureConfig.new
    @feature2.feature = "feature-name2"
    @feature2.variations = [@variation1, @variation2]
  end

  def teardown
    super
    # No need to verify FakeConfig as it's not a mock with expectations
  end

  # Test that metrics are correctly registered and sent upon flushing
  def test_metrics
    # Initialize MetricsProcessor
    metrics_processor = MetricsProcessor.new
    metrics_processor.init(@connector, @config, @callback)

    # Wait until MetricsProcessor signals readiness
    @callback.wait_until_ready

    # Register evaluations for two features and two variations each
    (1..3).each { metrics_processor.register_evaluation(target: @target, feature_config: @feature1, variation: @variation1) }
    (1..3).each { metrics_processor.register_evaluation(target: @target, feature_config: @feature1, variation: @variation2) }
    (1..3).each { metrics_processor.register_evaluation(target: @target, feature_config: @feature2, variation: @variation1) }
    (1..3).each { metrics_processor.register_evaluation(target: @target, feature_config: @feature2, variation: @variation2) }

    # Verify that the frequency map has the correct number of entries and counts
    freq_map = metrics_processor.send(:get_frequency_map)
    assert_equal 4, freq_map.size, "Not enough pending metrics"
    freq_map.each_value { |value| assert_equal 3, value, "Metric counter mismatch" }

    # Manually trigger flushing of metrics
    metrics_processor.send(:run_one_iteration)

    # After flushing, the frequency map should be empty
    assert_equal 0, freq_map.size, "Not all pending metrics were flushed"

    # Ensure that metrics have been captured by the connector
    assert_equal 1, @connector.captured_metrics.size, "Expected exactly one metrics payload to be captured"

    # Verify that the target_data includes just the single target used
    captured_metrics = @connector.captured_metrics.first
    assert_equal 1, captured_metrics.target_data.size, "There should only be 1 target"

    # Verify target attributes
    assert_target_data(captured_metrics.target_data)

    # Verify that metrics_data contains the correct number of metrics
    assert_equal 4, captured_metrics.metrics_data.size, "Incorrect number of metrics data entries"

    # Verify each metrics_data entry has the expected number of attributes
    captured_metrics.metrics_data.each do |metric_data|
      assert_equal 6, metric_data.attributes.size, "Too many attributes in metrics_data"
    end
  end

  # Helper method to assert target data correctness
  def assert_target_data(target_data)
    targets = {}
    target_data.each do |td|
      targets[td.identifier] = td
      if td.identifier == "target-id"
        td.attributes.each do |kv|
          # Access using method calls instead of hash-like access
          assert_equal "location", kv.key, "Incorrect attribute key for target"
          assert_equal "emea", kv.value, "Incorrect attribute value for target"
        end
      elsif td.identifier == "__global__cf_target"
        # Optionally, assert attributes for the global target if necessary
        # Example:
        # td.attributes.each do |kv|
        #   assert_equal "some_global_attribute_key", kv.key, "Incorrect global attribute key"
        #   assert_equal "some_value", kv.value, "Incorrect global attribute value"
        # end
      end
    end


  end


  # Test that FrequencyMap increments correctly
  def test_frequency_map_increment
    map = MetricsProcessor::FrequencyMap.new

    event1 = MetricsEvent.new(feature_config: @feature1,target: @target, variation: @variation1)
    event2 = MetricsEvent.new(feature_config: @feature2, target: @target, variation: @variation2)

    map.increment(event1)
    map.increment(event2)
    map.increment(event1)
    map.increment(event2)

    assert_equal 2, map[event1]
    assert_equal 2, map[event2]
  end

  # Test that FrequencyMap drains correctly to a new map
  def test_frequency_map_drain_to_map
    map = MetricsProcessor::FrequencyMap.new

    event1 = MetricsEvent.new(feature_config: @feature1, target: @target, variation: @variation1)
    event2 = MetricsEvent.new(feature_config: @feature2, target: @target, variation: @variation2)

    map.increment(event1)
    map.increment(event2)
    map.increment(event1)
    map.increment(event2)

    new_map = map.drain_to_map

    assert_equal 0, map.size, "Original map should be empty after draining"
    assert_equal 2, new_map.size, "New map should contain 2 entries after draining"
    assert_equal 2, new_map[event1]
    assert_equal 2, new_map[event2]
  end

  # Test equality and hash behavior of MetricsEvent
  def test_comparable_metrics_event_equals_and_hash
    event1 = MetricsEvent.new(feature_config: @feature1, target: @target, variation: @variation1)
    event2 = MetricsEvent.new(feature_config: @feature1, target: @target, variation: @variation1)

    assert_equal event1, event2, "Events with same feature and variation should be equal"
    assert_equal event1.hash, event2.hash, "Hashes of equal events should be identical"

    event3 = MetricsEvent.new(feature_config: @feature2, target: @target, variation: @variation2)
    refute_equal event1, event3, "Events with different features or variations should not be equal"
  end

  # Test that metrics are not automatically flushed when buffer is full
  def test_does_not_flush_map_when_buffer_fills
    # Adjust buffer_size to a small number to test buffer limit warnings
    @config.buffer_size = 2

    metrics_processor = MetricsProcessor.new
    metrics_processor.init(@connector, @config, @callback)

    # Wait until MetricsProcessor signals readiness
    @callback.wait_until_ready

    # Register evaluations exceeding the buffer size
    # Since automatic flushing on buffer full is disabled, all should be registered until buffer limit
    metrics_processor.register_evaluation(target: @target, feature_config: @feature1, variation: @variation1)
    metrics_processor.register_evaluation(target: @target,feature_config: @feature1,variation: @variation2)
    metrics_processor.register_evaluation(target: @target,feature_config: @feature2, variation: @variation1) # This should exceed buffer

    # Since buffer_size is 2, the third registration should not be added and a warning should be issued
    freq_map = metrics_processor.send(:get_frequency_map)
    assert_equal 2, freq_map.size, "Frequency map should only have 2 entries due to buffer limit"

    # The counts for the first two events should be 1
    freq_map.each_value { |value| assert_equal 1, value, "Metric counter mismatch due to buffer limit" }

    # Ensure that no metrics have been flushed automatically
    assert_equal 0, @connector.captured_metrics.size, "No metrics should have been flushed automatically"

    # Now, manually trigger flushing
    metrics_processor.send(:run_one_iteration)

    # After flushing, captured_metrics should have one metrics payload
    assert_equal 1, @connector.captured_metrics.size, "Expected one metrics payload after manual flushing"

    # Verify that only the first two metrics were sent
    captured_metrics = @connector.captured_metrics.first
    assert_equal 2, captured_metrics.metrics_data.size, "Only two metrics should have been sent"

    # Check that target_data includes only the single target
    assert_equal 1, captured_metrics.target_data.size, "There should only be 1"
  end

  # Additional tests can be added here to cover more scenarios

end
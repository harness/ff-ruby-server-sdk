require "minitest/autorun"
require "ff/ruby/server/sdk"
require 'set'

class MetricsProcessorTest < Minitest::Test

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
      @latch.wait 30
    end
  end

  class TestConnector < Connector
    def initialize
      @captured_metrics = []
      @post_metrics_latch = Concurrent::CountDownLatch.new(1)
    end

    def post_metrics(metrics)
      @captured_metrics.push metrics
      @post_metrics_latch.count_down

      puts metrics.to_s.gsub "},", "},\n"

      metrics.target_data.each do |target|
        puts "target: #{target.identifier} #{target.name}"
        target.attributes do |attr, value|
          puts "        #{attr}=#{value}"
        end
        target.attributes do |attr, value|
          puts "        #{attr}=#{value}"
        end
      end

      metrics.metrics_data.each do |metrics_row|
        puts "metrics: #{metrics_row.count}"
        metrics_row.attributes.each do |kv|
          unless kv.key.start_with?("SDK_")
            puts "         #{kv.key}=#{kv.value}"
          end
        end
      end
    end

    def get_flags
      print "get_flags"
      []
    end

    def get_segments
      print "get_segments"
      []
    end

    def get_captured_metrics
      @captured_metrics
    end

    def wait_for_metrics
      puts "Waiting for metrics to be posted..."
      @post_metrics_latch.wait 30
    end

  end

  def initialize(name)
    super

    @target = Target.new "target-name", "target-id", attributes = { "location": "emea" }

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

  def test_metrics

    logger = Logger.new(STDOUT)
    callback = TestCallback.new
    connector = TestConnector.new
    config = Minitest::Mock.new
    config.expect :kind_of?, true, [Config.class]
    config.expect :metrics_service_acceptable_duration, 10000

    (1..20).each { |_| config.expect :buffer_size, 10 }
    (1..20).each { |_| config.expect :logger, logger }

    metrics_processor = MetricsProcessor.new
    metrics_processor.init connector, config, callback

    callback.wait_until_ready

    # Here we test register_evaluation then run_one_iteration
    (1..3).each { metrics_processor.register_evaluation @target, @feature1, @variation1 }
    (1..3).each { metrics_processor.register_evaluation @target, @feature1, @variation2 }
    (1..3).each { metrics_processor.register_evaluation @target, @feature2, @variation1 }
    (1..3).each { metrics_processor.register_evaluation @target, @feature2, @variation2 }

    freq_map = metrics_processor.send :get_frequency_map
    assert_equal 4, freq_map.size, "not enough pending metrics"

    freq_map.each_value { |value| assert_equal 3, value, "metric counter mismatch" }

    metrics_processor.send :run_one_iteration

    assert_equal 0, freq_map.size, "not all pending metrics were flushed"
    assert_equal 1, connector.get_captured_metrics.size
    assert_equal 1, connector.get_captured_metrics[0].target_data.size, "there should only be 1 targets"

    connector.get_captured_metrics.each do |metric|
      metric.metrics_data.each do |metric_data|
        assert_equal 6, metric_data.attributes.size, "too many attributes"
      end
    end

    assert_target_data connector.get_captured_metrics[0].target_data
  end

  def test_multiple_threads_calling_send_data_and_reset_cache
    logger = Logger.new(STDOUT)
    callback = TestCallback.new
    connector = TestConnector.new
    config = Minitest::Mock.new
    config.expect :kind_of?, true, [Config]
    config.expect :metrics_service_acceptable_duration, 10000

    def config.logger
      @logger ||= Logger.new(STDOUT)
    end

    metrics_processor = MetricsProcessor.new
    metrics_processor.init(connector, config, callback)

    callback.wait_until_ready

    # Register evaluations
    (1..10).each do |i|
      feature = OpenapiClient::FeatureConfig.new
      feature.feature = "feature-#{i}"
      variation = OpenapiClient::Variation.new
      variation.identifier = "variation-#{i}"
      variation.value = "value-#{i}"
      variation.name = "Test-#{i}"

      variation2 = OpenapiClient::Variation.new
      variation2.identifier = "variation2-#{i}"
      variation2.value = "value2-#{i}"
      variation2.name = "Test2-#{i}"
      feature.variations = [variation, @variation2]
      metrics_processor.register_evaluation(@target, feature, variation)
    end

    # Define a method to call send_data_and_reset_cache
    send_metrics = Proc.new do
      metrics_processor.send(:send_data_and_reset_cache, metrics_processor.send(:get_frequency_map), metrics_processor.instance_variable_get(:@target_metrics))
    end

    # Spawn multiple threads to call send_data_and_reset_cache concurrently
    threads = []
    5.times do
      threads << Thread.new { send_metrics.call }
    end

    # Wait for all threads to complete
    threads.each(&:join)

    # Verify that post_metrics was called exactly once
    assert_equal 1, connector.get_captured_metrics.size, "post_metrics should be called only once despite multiple concurrent calls"

    # Verify that metrics_data contains all registered metrics
    metrics_data = connector.get_captured_metrics[0].metrics_data
    assert_equal 10, metrics_data.size, "All 10 metrics should be sent"

    # Verify that target_data contains the global target
    assert_equal 1, connector.get_captured_metrics[0].target_data.size, "There should be one target data entry"
    target_data = connector.get_captured_metrics[0].target_data.first
    assert_equal @target.identifier, target_data.identifier, "Target should be included in target metrics"
  end

  def test_send_data_and_reset_cache_no_evaluations
    logger = Logger.new(STDOUT)
    callback = TestCallback.new
    connector = TestConnector.new
    config = Minitest::Mock.new
    config.expect :kind_of?, true, [Config]
    config.expect :metrics_service_acceptable_duration, 10000

    def config.logger
      @logger ||= Logger.new(STDOUT)
    end

    metrics_processor = MetricsProcessor.new
    metrics_processor.init(connector, config, callback)

    callback.wait_until_ready

    # Define a method to call send_data_and_reset_cache
    send_metrics = Proc.new do
      metrics_processor.send(:send_data_and_reset_cache, metrics_processor.send(:get_frequency_map), metrics_processor.instance_variable_get(:@target_metrics))
    end

    # Spawn multiple threads to call send_data_and_reset_cache concurrently
    threads = []
    5.times do
      threads << Thread.new { send_metrics.call }
    end

    # Wait for all threads to complete
    threads.each(&:join)

    # Verify that post_metrics was called exactly once
    assert_equal 0, connector.get_captured_metrics.size, "post_metrics should not be called as no evaluations regisstered"
  end

  def test_multiple_threads_calling_register_evaluation
    logger = Logger.new(STDOUT)
    callback = TestCallback.new
    connector = TestConnector.new
    config = Minitest::Mock.new
    config.expect :kind_of?, true, [Config]
    config.expect :metrics_service_acceptable_duration, 10000

    def config.logger
      @logger ||= Logger.new(STDOUT)
    end

    metrics_processor = MetricsProcessor.new
    metrics_processor.init(connector, config, callback)

    callback.wait_until_ready

    # Define a method to register evaluations
    register_evals = Proc.new do |feature_id|
      feature = OpenapiClient::FeatureConfig.new
      feature.feature = "feature-#{feature_id}"
      variation = OpenapiClient::Variation.new
      variation.identifier = "variation-#{feature_id}"
      variation.value = "value-#{feature_id}"
      variation.name = "Test-#{feature_id}"

      variation2 = OpenapiClient::Variation.new
      variation2.identifier = "variation2-#{feature_id}"
      variation2.value = "value2-#{feature_id}"
      variation2.name = "Test2-#{feature_id}"

      feature.variations = [variation, variation2]
      metrics_processor.register_evaluation(@target, feature, variation)
    end

    # Number of threads and evaluations per thread
    thread_count = 10
    evals_per_thread = 100

    # Generate expected metrics identifiers as a Set
    expected_metrics_set = Set.new
    (0...thread_count).each do |i|
      (0...evals_per_thread).each do |j|
        feature_id = "#{i}-#{j}"
        feature_name = "feature-#{feature_id}"
        variation_id = "variation-#{feature_id}"
        expected_metrics_set.add([feature_name, variation_id])
      end
    end

    # Spawn multiple threads to register evaluations concurrently
    threads = []
    thread_count.times do |i|
      threads << Thread.new do
        evals_per_thread.times do |j|
          register_evals.call("#{i}-#{j}")
        end
      end
    end

    # Wait for all threads to complete
    threads.each(&:join)

    # Verify that the metrics map contains the correct number of unique metrics
    freq_map = metrics_processor.send(:get_frequency_map)
    expected_metrics = thread_count * evals_per_thread
    assert_equal expected_metrics, freq_map.size, "Metrics map should contain #{expected_metrics} unique metrics"

    # Verify that each metric has been registered exactly once
    freq_map.each_value do |count|
      assert_equal 1, count, "Each metric should have been registered exactly once"
    end

    # Verify the presence and correctness of each expected metric
    metric_found = {}
    expected_metrics_set.each { |metric| metric_found[metric] = false }

    freq_map.each_key do |metrics_event|
      # Extract feature name and variation identifier from the metrics_event
      actual_feature_name = metrics_event.feature_config.feature
      actual_variation_id = metrics_event.variation.identifier

      # Create the key for the current metric
      metric_key = [actual_feature_name, actual_variation_id]

      if metric_found.key?(metric_key)
        metric_found[metric_key] = true
      else
        assert false, "Unexpected metric with Feature: #{actual_feature_name}, Variation: #{actual_variation_id}"
      end
    end

  end

  def test_error_during_send_data_and_reset_cache
    logger = Logger.new(STDOUT)
    callback = TestCallback.new
    connector = TestConnector.new
    config = Minitest::Mock.new
    config.expect :kind_of?, true, [Config]
    config.expect :metrics_service_acceptable_duration, 10000

    def config.logger
      @logger ||= Logger.new(STDOUT)
    end

    # Mock the connector to raise an exception when post_metrics is called
    connector.stub :post_metrics, proc { raise StandardError, "Simulated connector failure" } do
      metrics_processor = MetricsProcessor.new
      metrics_processor.init(connector, config, callback)

      callback.wait_until_ready

      # Register some evaluations
      feature = OpenapiClient::FeatureConfig.new
      feature.feature = "feature-error-test"
      variation = OpenapiClient::Variation.new
      variation.identifier = "variation-error-test"
      variation.value = "value-error-test"
      variation.name = "Test-Error"

      variation2 = OpenapiClient::Variation.new
      variation2.identifier = "variation2-error-test"
      variation2.value = "value2-error-test"
      variation2.name = "Test2-Error"

      feature.variations = [variation, variation2]
      metrics_processor.register_evaluation(@target, feature, variation)

      # Attempt to send data, which should raise an exception
      metrics_processor.send(:send_data_and_reset_cache, metrics_processor.send(:get_frequency_map), metrics_processor.instance_variable_get(:@target_metrics))

      # Verify that metrics maps are cleared despite the error
      freq_map = metrics_processor.send(:get_frequency_map)
      assert_empty freq_map, "Evaluation metrics map should be cleared even if an error occurs"

      target_metrics_map = metrics_processor.instance_variable_get(:@target_metrics)
      assert_empty target_metrics_map, "Target metrics map should be cleared even if an error occurs"

      # Verify that the MetricsProcessor remains operational by registering another evaluation
      feature_new = OpenapiClient::FeatureConfig.new
      feature_new.feature = "feature-new"
      variation_new = OpenapiClient::Variation.new
      variation_new.identifier = "variation-new"
      variation_new.value = "value-new"
      variation_new.name = "Test-New"

      variation2_new = OpenapiClient::Variation.new
      variation2_new.identifier = "variation2-new"
      variation2_new.value = "value2-new"
      variation2_new.name = "Test2-New"

      # Ensure that the new evaluation is registered correctly
      freq_map = metrics_processor.send(:get_frequency_map)
      assert_equal 1, freq_map.size, "New evaluation should be registered successfully after an error"

      assert_equal 1, freq_map.values.first, "New evaluation count should be 1"
    end
  end

  def assert_target_data(target_data)
    targets = {}

    target_data.each do |target_data|
      targets[target_data.identifier] = true
      if target_data.identifier == "target-id"
        target_data.attributes.each do |kv|
          assert_equal :location, kv.key
          assert_equal "emea", kv.value
        end
      end
    end

    assert targets.key?("target-id")
  end

  def test_comparable_metrics_event_equals_and_hash

    event1 = MetricsEvent.new(@feature1, @target, @variation1, Logger.new(STDOUT))
    event2 = MetricsEvent.new(@feature1, @target, @variation1, Logger.new(STDOUT))

    assert(event1 == event2)

    event1 = MetricsEvent.new(@feature1, @target, @variation1, Logger.new(STDOUT))
    event2 = MetricsEvent.new(@feature2, @target, @variation2, Logger.new(STDOUT))

    assert(event1 != event2)
  end

  def test_metrics_processor_prevents_invalid_metrics_event
    logger = Logger.new(STDOUT)
    callback = TestCallback.new
    connector = TestConnector.new
    config = Minitest::Mock.new
    config.expect :kind_of?, true, [Config.class]
    config.expect :metrics_service_acceptable_duration, 10000

    (1..20).each { |_| config.expect :buffer_size, 10 }
    (1..20).each { |_| config.expect :logger, logger }

    metrics_processor = MetricsProcessor.new
    metrics_processor.init(connector, config, callback)

    callback.wait_until_ready

    # Attempt to register invalid evaluations
    metrics_processor.register_evaluation(@target, nil, @variation1)
    metrics_processor.register_evaluation(@target, nil, nil)
    metrics_processor.register_evaluation(nil, @feature1, nil)

    # Register some valid evaluations
    metrics_processor.register_evaluation(@target, @feature1, @variation1)
    metrics_processor.register_evaluation(@target, @feature2, @variation2)
    # Nil target, which is a valid input to variation methods
    metrics_processor.register_evaluation(nil, @feature2, @variation2)

    # Run iteration
    metrics_processor.send(:run_one_iteration)

    # Wait for metrics to be posted
    connector.wait_for_metrics

    # Check that only valid metrics are sent
    captured_metrics = connector.get_captured_metrics
    assert_equal 1, captured_metrics.size, "Only one metrics batch should be sent"

    metrics_data = captured_metrics[0].metrics_data

    # Since we have two valid events, two metrics_data should be present
    assert_equal 2, metrics_data.size, "Invalid metrics should be ignored"

    # Verify that only valid features are present in sent metrics
    sent_features = metrics_data.map { |md| md.attributes.find { |kv| kv.key == "featureName" }.value }
    assert_includes(sent_features, "feature-name")
    assert_includes(sent_features, "feature-name2") # Assuming @feature2 has "feature-name2"

    # Invalid event is not among the sent features
    refute_includes(sent_features, nil, "Invalid MetricsEvent should not be included in metrics_data")

    # Valid events were processed correctly
    assert_equal 2, metrics_data.size, "There should be two metrics_data entries for valid events"

    # Target data is still correctly sent
    assert_equal 1, captured_metrics[0].target_data.size, "There should only be a single target"
  end

  def test_metrics_event_eql_with_invalid_object
    event = MetricsEvent.new(@feature1, @target, @variation1, Logger.new(STDOUT))
    non_event = "Not a MetricsEvent"

    refute_equal(event, non_event, "MetricsEvent should not be equal to a non-MetricsEvent object")
  end

end
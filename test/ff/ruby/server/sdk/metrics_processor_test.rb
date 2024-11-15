require "minitest/autorun"
require "ff/ruby/server/sdk"
require "concurrent/atomics"

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

    @target = Target.new "target-name", "target-id", attributes={"location": "emea"}

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
    @feature1.variations = [ @variation1, @variation2 ]

    @feature2 = OpenapiClient::FeatureConfig.new
    @feature2.feature = "feature-name2"
    @feature2.variations = [ @variation1, @variation2 ]
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

    freq_map.each_value { |value| assert_equal 3, value, "metric counter mismatch"}

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

  def test_frequency_map_increment

    map = MetricsProcessor::FrequencyMap.new

    event1 = MetricsEvent.new(@feature1, @target, @variation1, Logger.new(STDOUT))
    event2 = MetricsEvent.new(@feature2, @target, @variation2, Logger.new(STDOUT))

    map.increment event1
    map.increment event2

    map.increment event1
    map.increment event2

    assert_equal 2, map[event1]
    assert_equal 2, map[event2]
  end

  def test_frequency_map_drain_to_map
    map = MetricsProcessor::FrequencyMap.new

    event1 = MetricsEvent.new(@feature1, @target, @variation1, Logger.new(STDOUT))
    event2 = MetricsEvent.new(@feature2, @target, @variation2, Logger.new(STDOUT))

    map.increment event1
    map.increment event2

    map.increment event1
    map.increment event2

    new_map = map.drain_to_map

    assert_equal 0, map.size
    assert_equal 2, new_map[event1]
    assert_equal 2, new_map[event2]
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
    metrics_processor.register_evaluation(@target,nil, @variation1)
    metrics_processor.register_evaluation(@target,nil, nil)
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
    event = MetricsEvent.new(@feature1, @target, @variation1,Logger.new(STDOUT))
    non_event = "Not a MetricsEvent"

    refute_equal(event, non_event, "MetricsEvent should not be equal to a non-MetricsEvent object")
  end

end
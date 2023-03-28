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
      print error
    end

    def wait_until_ready
      print "Wait for metrics processor to start"
      @latch.wait 30
    end
  end

  class TestConnector < Connector
    def initialize
      @captured_metrics = []
    end

    def post_metrics(metrics)
      @captured_metrics.push metrics
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
  end

  def initialize(name)
    super

    @target = Target.new "target-name", "target-id"

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
    config = MiniTest::Mock.new
    config.expect :kind_of?, true, [Config.class]
    config.expect :metrics_service_acceptable_duration, 10000

    (1..20).each { |_| config.expect :buffer_size, 10 }
    (1..20).each { |_| config.expect :logger, logger }

    metrics_processor = MetricsProcessor.new
    metrics_processor.init connector, config, callback

    callback.wait_until_ready

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


    # if global target is set then targets should still include targets
  end

  def test_frequency_map_increment

    map = MetricsProcessor::FrequencyMap.new

    event1 = MetricsEvent.new(@feature1, @target, @variation1)
    event2 = MetricsEvent.new(@feature2, @target, @variation2)

    map.increment event1
    map.increment event2

    map.increment event1
    map.increment event2

    assert_equal 2, map[event1]
    assert_equal 2, map[event2]
  end

  def test_frequency_map_drain_to_map
    map = MetricsProcessor::FrequencyMap.new

    event1 = MetricsEvent.new(@feature1, @target, @variation1)
    event2 = MetricsEvent.new(@feature2, @target, @variation2)

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

    event1 = MetricsEvent.new(@feature1, @target, @variation1)
    event2 = MetricsEvent.new(@feature1, @target, @variation1)

    assert(event1 == event2)

    event1 = MetricsEvent.new(@feature1, @target, @variation1)
    event2 = MetricsEvent.new(@feature2, @target, @variation2)

    assert(event1 != event2)
  end


end
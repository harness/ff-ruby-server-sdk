require "time"
require "concurrent-ruby"

require_relative "../dto/target"
require_relative "../../sdk/version"
require_relative "../common/closeable"
require_relative "../common/sdk_codes"
require_relative "../api/metrics_event"
require_relative "../api/summary_metrics"

class MetricsProcessor < Closeable

  class FrequencyMap < Concurrent::Map
    def initialize(options = nil, &block)
      super
    end

    def increment(key)
      compute(key) do |old_value|
        if old_value == nil;
          1
        else
          old_value + 1
        end
      end
    end

    def get(key)
      self[key]
    end

    # TODO Will be removed in V2 in favour of simplified clearing. Currently not used outside of tests.
    def drain_to_map
      result = {}
      each_key do |key|
        result[key] = 0
      end
      result.each_key do |key|
        value = get_and_set(key, 0)
        result[key] = value
        delete_pair(key, 0)
      end
      result
    end
  end

  def init(connector, config, callback)

    unless connector.kind_of?(Connector)
      raise "The 'connector' must be of '" + Connector.to_s + "' data type"
    end

    unless callback.kind_of?(MetricsCallback)
      raise "The 'callback' must be of '" + MetricsCallback.to_s + "' data type"
    end

    unless config.kind_of?(Config)
      raise "The 'config' must be of '" + Config.to_s + "' data type"
    end

    @config = config
    @callback = callback
    @connector = connector

    @sdk_type = "SDK_TYPE"
    @target_attribute = "target"
    @global_target_identifier = "__global__cf_target" # <--- This target identifier is used to aggregate and send data for all
    #                                             targets as a summary
    @global_target = Target.new("RubySDK1", identifier = @global_target_identifier, name = @global_target_name)
    @ready = false
    @jar_version = Ff::Ruby::Server::Sdk::VERSION
    @server = "server"
    @sdk_version = "SDK_VERSION"
    @sdk_language = "SDK_LANGUAGE"
    @global_target_name = "Global Target"
    @feature_name_attribute = "featureName"
    @variation_identifier_attribute = "variationIdentifier"

    @executor = Concurrent::FixedThreadPool.new(10)

    @evaluation_metrics = FrequencyMap.new
    @target_metrics = Concurrent::Map.new

    # Keep track of targets that have already been sent to avoid sending them again
    @seen_targets = Concurrent::Map.new

    @max_buffer_size = config.buffer_size - 1

    # Max 100k targets per interval
    @max_targets_buffer_size = 100000

    @evaluation_warning_issued = Concurrent::AtomicBoolean.new
    @target_warning_issued = Concurrent::AtomicBoolean.new

    @callback.on_metrics_ready
  end

  def start
    @config.logger.debug "Starting metrics processor with request interval: " + @config.frequency.to_s
    start_async
  end

  def stop
    @config.logger.debug "Stopping metrics processor"
    stop_async
  end

  def close
    stop
    @config.logger.debug "Closing metrics processor"
  end

  def register_evaluation(target, feature_config, variation)
    register_evaluation_metric(feature_config, variation)
    register_target_metric(target)
  end

  private

  def register_evaluation_metric(feature_config, variation)
    if @evaluation_metrics.size > @max_buffer_size
      unless @evaluation_warning_issued.true?
        SdkCodes.warn_metrics_evaluations_max_size_exceeded(@config.logger)
        @evaluation_warning_issued.make_true
      end
      return
    end

    event = MetricsEvent.new(feature_config, @global_target, variation)
    @evaluation_metrics.increment event
  end

  def register_target_metric(target)
    if @target_metrics.size > @max_targets_buffer_size
      unless @target_warning_issued.true?
        SdkCodes.warn_metrics_targets_max_size_exceeded(@config.logger)
        @target_warning_issued.make_true
      end
      return
    end

    if target.is_private
      return
    end

    already_seen = @seen_targets.put_if_absent(target.identifier, true)

    if already_seen
      return
    end

    @target_metrics.put(target.identifier, target)
  end

  def run_one_iteration
    send_data_and_reset_cache(@evaluation_metrics, @target_metrics)

    @config.logger.debug "metrics: frequency map size #{@evaluation_metrics.size}. targets map size #{@target_metrics.size} global target size #{@seen_targets.size}"
  end

  def send_data_and_reset_cache(evaluation_metrics_map, target_metrics_map)
    # Clone and clear evaluation metrics map
    evaluation_metrics_map_clone = Concurrent::Map.new

    evaluation_metrics_map.each_pair do |key, value|
      evaluation_metrics_map_clone[key] = value
    end

    evaluation_metrics_map.clear
    target_metrics_map_clone = Concurrent::Map.new

    target_metrics_map.each_pair do |key, value|
      target_metrics_map_clone[key] = value
    end

    target_metrics_map.clear

    @evaluation_warning_issued.make_false
    @target_warning_issued.make_false

    metrics = prepare_summary_metrics_body(evaluation_metrics_map_clone, target_metrics_map_clone)

    unless metrics.metrics_data.empty?
      start_time = (Time.now.to_f * 1000).to_i
      @connector.post_metrics(metrics)
      end_time = (Time.now.to_f * 1000).to_i
      if end_time - start_time > @config.metrics_service_acceptable_duration
        @config.logger.debug "Metrics service API duration=[" + (end_time - start_time).to_s + "]"
      end
    end
  end

  def prepare_summary_metrics_body(evaluation_metrics_map, target_metrics_map)
    metrics = OpenapiClient::Metrics.new({ :target_data => [], :metrics_data => [] })

    total_count = 0
    evaluation_metrics_map.each do |key, value|
      # Components should not be missing, but as we transition to Ruby 3 support, let's
      # add validation.
      # Initialize an array to collect missing components
      missing_components = []

      # Check each required component and add to missing_components if absent
      missing_components << 'feature_config' unless key.respond_to?(:feature_config) && key.feature_config
      missing_components << 'variation' unless key.respond_to?(:variation) && key.variation
      missing_components << 'target' unless key.respond_to?(:target) && key.target

      # If any components are missing, log a detailed warning and skip processing
      unless missing_components.empty?
        @config.logger.warn "Skipping invalid metrics event: missing #{missing_components.join(', ')} in key: #{key.inspect}, full details: #{key.inspect}"
        next
      end

      total_count += value
      metrics_data = OpenapiClient::MetricsData.new({ :attributes => [] })
      metrics_data.timestamp = (Time.now.to_f * 1000).to_i
      metrics_data.count = value
      metrics_data.metrics_type = "FFMETRICS"
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @feature_name_attribute, :value => key.feature_config.feature }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @variation_identifier_attribute, :value => key.variation.identifier }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @target_attribute, :value => @global_target_identifier }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @sdk_type, :value => @server }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @sdk_language, :value => "ruby" }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @sdk_version, :value => @jar_version }))
      metrics.metrics_data.push(metrics_data)
    end
    @config.logger.debug "Pushed #{total_count} metric evaluations to server. metrics_data count is #{evaluation_metrics_map.size}.  target_data count is #{target_metrics_map.size}"

    target_metrics_map.each_pair do |_, value|
      add_target_data(metrics, value)
    end

    metrics
  end

  def add_target_data(metrics, target)

    target_data = OpenapiClient::TargetData.new({ :attributes => [] })
    private_attributes = target.private_attributes

    attributes = target.attributes
    attributes.each do |k, v|
      key_value = OpenapiClient::KeyValue.new
      if !private_attributes.empty?
        unless private_attributes.include?(k)
          key_value = OpenapiClient::KeyValue.new({ :key => k, :value => v.to_s })
        end
      else
        key_value = OpenapiClient::KeyValue.new({ :key => k, :value => v.to_s })
      end
      target_data.attributes.push(key_value)
    end
    target_data.identifier = target.identifier
    if target.name == nil || target.name == ""
      target_data.name = target.identifier
    else
      target_data.name = target.name
    end
    metrics.target_data.push(target_data)
  end

  def start_async
    @config.logger.debug "Async starting: " + self.to_s
    @ready = true
    @thread = Thread.new do
      @config.logger.debug "Async started: " + self.to_s
      while @ready do
        unless @initialized
          @initialized = true
          SdkCodes::info_metrics_thread_started @config.logger
        end
        sleep(@config.frequency)
        run_one_iteration
      end
    end
    @thread.run
  end

  def stop_async
    @ready = false
    @initialized = false
  end

  def get_version
    Ff::Ruby::Server::Sdk::VERSION
  end

  def get_frequency_map
    @evaluation_metrics
  end

end

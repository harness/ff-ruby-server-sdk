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
        if old_value == nil; 1 else old_value + 1 end
      end
    end

    def get(key)
      self[key]
    end

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
    @global_target_set = Set[]
    @staging_target_set = Set[]
    @target_attribute = "target"
    @global_target = "__global__cf_target" # <--- This target identifier is used to aggregate and send data for all
    #                                             targets as a summary

    @ready = false
    @jar_version = ""
    @server = "server"
    @sdk_version = "SDK_VERSION"
    @sdk_language = "SDK_LANGUAGE"
    @global_target_name = "Global Target"
    @feature_name_attribute = "featureName"
    @variation_identifier_attribute = "variationIdentifier"

    @executor = Concurrent::FixedThreadPool.new(10)

    @frequency_map = FrequencyMap.new

    @max_buffer_size = config.buffer_size - 1

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

    if @frequency_map.size > @max_buffer_size
      @config.logger.warn "metrics buffer is full #{@frequency_map.size} - flushing metrics"
      @executor.post do
        run_one_iteration
      end
    end

    event = MetricsEvent.new(feature_config, target, variation)
    @frequency_map.increment event
  end

  private

  def run_one_iteration
    send_data_and_reset_cache @frequency_map.drain_to_map

    @config.logger.debug "metrics: frequency map size #{@frequency_map.size}. global target size #{@global_target_set.size}"
  end

  def send_data_and_reset_cache(map)
    metrics = prepare_summary_metrics_body(map)

    if !metrics.metrics_data.empty? && !metrics.target_data.empty?
      start_time = (Time.now.to_f * 1000).to_i
      @connector.post_metrics(metrics)
      end_time = (Time.now.to_f * 1000).to_i
      if end_time - start_time > @config.metrics_service_acceptable_duration
        @config.logger.debug "Metrics service API duration=[" + (end_time - start_time).to_s + "]"
      end
    end

    @global_target_set.merge(@staging_target_set)
    @staging_target_set.clear

  end

  def prepare_summary_metrics_body(freq_map)
    metrics = OpenapiClient::Metrics.new({ :target_data => [], :metrics_data => [] })
    add_target_data(metrics, Target.new(name = @global_target_name, identifier = @global_target))
    freq_map.each_key do |key|
      add_target_data(metrics, key.target)
    end
    total_count = 0
    freq_map.each do |key, value|
      total_count += value
      metrics_data = OpenapiClient::MetricsData.new({ :attributes => [] })
      metrics_data.timestamp = (Time.now.to_f * 1000).to_i
      metrics_data.count = value
      metrics_data.metrics_type = "FFMETRICS"
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @feature_name_attribute, :value => key.feature_config.feature }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @variation_identifier_attribute, :value => key.variation.identifier }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @target_attribute, :value => @global_target }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @sdk_type, :value => @server }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @sdk_language, :value => "ruby" }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @sdk_version, :value => @jar_version }))
      metrics.metrics_data.push(metrics_data)
    end
    @config.logger.debug "Pushed #{total_count} metric evaluations to server. metrics_data count is #{freq_map.size}"

    metrics
  end

  def add_target_data(metrics, target)

    target_data = OpenapiClient::TargetData.new({ :attributes => [] })
    private_attributes = target.private_attributes

    if !@staging_target_set.include?(target) && !@global_target_set.include?(target) && !target.is_private
      @staging_target_set.add(target)
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
    @frequency_map
  end

end

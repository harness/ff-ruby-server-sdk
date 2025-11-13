require "time"
require 'thread'
require "set"

require_relative "../dto/target"
require_relative "../../sdk/version"
require_relative "../common/closeable"
require_relative "../common/sdk_codes"
require_relative "../api/summary_metrics"

class MetricsProcessor < Closeable
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
    @ready = false
    @jar_version = Ff::Ruby::Server::Sdk::VERSION
    @server = "server"
    @sdk_version = "SDK_VERSION"
    @sdk_language = "SDK_LANGUAGE"
    @global_target_name = "Global Target"
    @feature_name_attribute = "featureName"
    @variation_identifier_attribute = "variationIdentifier"

    # Evaluation and target metrics
    @metric_maps_mutex = Mutex.new
    @evaluation_metrics = {}
    @target_metrics = {}
    @target_metrics_max_payload = 100000

    # Keep track of targets that have already been sent to avoid sending them again. We track a max 500K targets
    # to prevent unbounded growth.
    @seen_targets_mutex = Mutex.new
    @seen_targets = Set.new

    # Mutex to protect aggregation and sending metrics at the end of an interval
    @send_data_mutex = Mutex.new

    @callback.on_metrics_ready
  end

  def start
    @config.logger.debug "Starting metrics processor with request interval: #{@config.frequency}"
    if @running
      @config.logger.warn "Metrics processor is already running."
    else
      start_async
    end
  end
  def stop
    @config.logger.debug "Stopping metrics processor"
    stop_async
  end

  def close
    stop
    @config.logger.debug "Closing metrics processor"
  end

  def register_evaluation(target, feature_name, variation_identifier)
    register_evaluation_metric(feature_name, variation_identifier)
    if target
      register_target_metric(target)
    end
  end

  private

  def register_evaluation_metric(feature_name, variation_identifier)
    # Guard clause to ensure feature_config, @global_target, and variation are valid.
    # While they should be, this adds protection for an edge case we are seeing where the the ConcurrentMap (now replaced with our own thread safe hash)
    # seemed to be accessing invalid areas of memory and seg faulting.
    # Issue being tracked in FFM-12192, and once resolved, can remove these checks in a future release && once the issue is resolved.
    unless feature_name && !feature_name.empty?
      @config.logger.warn("Skipping invalid MetricsEvent: feature_config is missing or incomplete. feature_config=#{feature_name.inspect}")
      return
    end

    unless variation_identifier && !variation_identifier.empty?
      @config.logger.warn("Skipping iInvalid MetricsEvent: variation is missing or incomplete. variation=#{variation_identifier.inspect}")
      return
    end

    @metric_maps_mutex.synchronize do
      key = "#{feature_name}\0#{variation_identifier}"
      @evaluation_metrics[key] = (@evaluation_metrics[key] || 0) + 1
    end
  end

  def register_target_metric(target)
    return if target.is_private

    add_to_target_metrics = @seen_targets_mutex.synchronize do
      if @seen_targets.include?(target.identifier)
        false
      else
        @seen_targets.add(target.identifier)
        true
      end
    end

    # Add to target_metrics if marked for inclusion
    dropped = @metric_maps_mutex.synchronize do
      if @target_metrics.size < @target_metrics_max_payload
        @target_metrics[target.identifier] = target
        false
      else
        true
      end
    end if add_to_target_metrics

    # If we had to drop the target, remove it from the seen list too, assume it will be readded later
    # avoids a situation where targets were marked seen but never really sent
    @seen_targets_mutex.synchronize do
      @seen_targets.delete(target.identifier)
    end if dropped

  end


  def run_one_iteration
    send_data_and_reset_cache(@evaluation_metrics, @target_metrics)
  end

  def send_data_and_reset_cache(evaluation_metrics_map, target_metrics_map)
    @send_data_mutex.synchronize do
      begin

        evaluation_metrics_map_clone, target_metrics_map_clone = @metric_maps_mutex.synchronize do
          # Check if we have metrics to send; if not, skip sending metrics
          if evaluation_metrics_map.empty? && target_metrics_map.empty?
            @config.logger.debug "No metrics to send. Skipping sending metrics this interval"
            return
          end

          # Deep clone the evaluation metrics
          cloned_evaluations = Marshal.load(Marshal.dump(evaluation_metrics_map)).freeze
          evaluation_metrics_map.clear

          # Deep clone the target metrics
          cloned_targets = Marshal.load(Marshal.dump(target_metrics_map)).freeze
          target_metrics_map.clear
          [cloned_evaluations, cloned_targets]

        end

        metrics = prepare_summary_metrics_body(evaluation_metrics_map_clone, target_metrics_map_clone)

        unless metrics.metrics_data.empty?
          start_time = (Time.now.to_f * 1000).to_i
          @connector.post_metrics(metrics)
          end_time = (Time.now.to_f * 1000).to_i
          if end_time - start_time > @config.metrics_service_acceptable_duration
            @config.logger.debug "Metrics service API duration=[" + (end_time - start_time).to_s + "]"
          end
        end
      rescue => e
        @config.logger.warn "Error when preparing and sending metrics: #{e.message}"
        @config.logger.warn e.backtrace&.join("\n") || "No backtrace available"
      end
    end
  end

  def prepare_summary_metrics_body(evaluation_metrics_clone, target_metrics_clone)
    metrics = OpenapiClient::Metrics.new({ :target_data => [], :metrics_data => [] })

    total_count = 0
    evaluation_metrics_clone.each do |key, value|
      feature_name, variation_identifier = key.split("\0", 2)

      # Although feature_name and variation_identifier should always be present,
      # this guard provides protection against an edge case where keys reference
      # other objects in memory. In versions <= 1.4.4, we were keying on the MetricsEvent
      # class (now deleted). To remediate this, we have transitioned to using strings as keys.
      # This issue is being tracked in FFM-12192. Once resolved, these checks can be safely
      # removed in a future release.
      # If any required data is missing, log a detailed warning and skip processing.
      unless feature_name && variation_identifier && value.is_a?(Integer) && value > 0
        @config.logger.warn "Skipping invalid metrics event: missing or invalid feature_name, variation_identifier, or count. Key: #{key.inspect}, Count: #{value.inspect}"
        next
      end

      total_count += value

      metrics_data = OpenapiClient::MetricsData.new({ :attributes => [] })
      metrics_data.timestamp = (Time.now.to_f * 1000).to_i
      metrics_data.count = value
      metrics_data.metrics_type = "FFMETRICS"
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @feature_name_attribute, :value => feature_name }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @variation_identifier_attribute, :value => variation_identifier }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @target_attribute, :value => @global_target_identifier }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @sdk_type, :value => @server }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @sdk_language, :value => "ruby" }))
      metrics_data.attributes.push(OpenapiClient::KeyValue.new({ :key => @sdk_version, :value => @jar_version }))
      metrics.metrics_data.push(metrics_data)
    end
    @config.logger.debug "Pushed #{total_count} metric evaluations to server. metrics_data count is #{evaluation_metrics_clone.size}.  target_data count is #{target_metrics_clone.size}"

    target_metrics_clone.each_pair do |_, value|
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
    @running = true
    @thread = Thread.new do
      @config.logger.debug "Async started: " + self.to_s
      mutex = Mutex.new
      condition = ConditionVariable.new

      while @ready
        unless @initialized
          @initialized = true
          SdkCodes::info_metrics_thread_started(@config.logger)
        end

        mutex.synchronize do
          # Wait for the specified interval or until notified
          condition.wait(mutex, @config.frequency)
        end

        # Re-check @ready before running the iteration
        run_one_iteration if @ready
      end
    end
  end


  def stop_async
    @ready = false
    @initialized = false
    if @thread && @thread.alive?
      @thread.join
      @config.logger.debug "Metrics processor thread has been stopped."
    end
    @running = false
  end


  def get_version
    Ff::Ruby::Server::Sdk::VERSION
  end

  def get_frequency_map
    @evaluation_metrics
  end

end

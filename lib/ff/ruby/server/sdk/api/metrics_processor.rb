require "time"
require "concurrent-ruby"

require_relative "../common/closeable"

class MetricsProcessor < Closeable

  def initialize(

    connector,
    config,
    callback
  )

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

    @jar_version = ""
    @server = "server"
    @sdk_version = "SDK_VERSION"
    @sdk_language = "SDK_LANGUAGE"
    @global_target_name = "Global Target"
    @feature_name_attribute = "featureName"
    @variation_identifier_attribute = "variationIdentifier"

    @queue = SizedQueue.new(@config.buffer_size)
    @executor = Concurrent::FixedThreadPool.new(100)

    @callback.on_metrics_ready
  end

  def start

    puts "Starting MetricsProcessor with request interval: " + @config.frequency.to_s
    start_async
  end

  def stop

    puts "Stopping MetricsProcessor"
    stop_async
  end

  def close

    stop
    puts "Closing MetricsProcessor"
  end

  def push_to_queue(

    target,
    feature_config,
    variation
  )

    @executor.post do

      event = MetricsEvent.new(feature_config, target, variation)
      @queue.push(event)
    end
  end

  def send_data_and_reset_cache(data)

    puts "Reading from queue and building cache"

    @jar_version = get_version

    unless data.empty?

      map = {}

      data.each do |event|

        new_value = 1
        current = map[event]

        if current != nil

          new_value = current + 1
        end

        map[event] = new_value
      end

      metrics = prepare_summary_metrics_body(map)

      if !metrics.metrics_data.empty? && !metrics.target_data.empty?

        start_time = (Time.now.to_f * 1000).to_i

        @connector.post_metrics(metrics)

        end_time = (Time.now.to_f * 1000).to_i

        if end_time - start_time > @config.metrics_service_acceptable_duration

          puts "Metrics service API duration=[" + (end_time - start_time).to_s + "]"
        end
      end

      @global_target_set.merge(@staging_target_set)
      @staging_target_set.clear
    end
  end

  protected

  def run_one_iteration

    puts "Async metrics iteration"

  end

end

def prepare_summary_metrics_body(data) end

private

def start_async

  puts "Async starting: " + self.to_s

  @ready = true

  @thread = Thread.new do

    puts "Async started: " + self.to_s

    while @ready do

      unless @initialized

        @initialized = true
        puts "MetricsProcessor initialized"
      end

      sleep(@config.frequency)

      run_one_iteration
    end

    @thread.run
  end

  def stop_async

    @ready = false
    @initialized = false
  end

  def prepare_summary_metrics_key(key) end

  def add_target(metrics, target) end

  def get_version

    nil
  end
end
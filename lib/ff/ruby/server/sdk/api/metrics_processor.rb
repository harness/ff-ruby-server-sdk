require_relative "../common/closeable"

class MetricsProcessor < Closeable

  def initialize(

    connector,
    config,
    callback
  )

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
  ) end

  def send_data_and_reset_cache(data) end

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

    @callback.on_metrics_ready

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
require_relative "evaluator"
require_relative "evaluation"
require_relative "auth_service"
require_relative "client_callback"
require_relative "update_processor"
require_relative "polling_processor"
require_relative "metrics_processor"
require_relative "storage_repository"
require_relative "inner_client_updater"
require_relative "inner_client_metrics_callback"
require_relative "inner_client_repository_callback"
require_relative "inner_client_flag_evaluate_callback"

require_relative "../connector/harness_connector"

class InnerClient < ClientCallback

  def initialize(api_key = nil, config = nil, connector = nil)

    if api_key == nil || api_key.empty?

      raise "SDK key is not provided"
    end

    if config == nil

      @config = ConfigBuilder.new.build
    else

      unless config.kind_of?(Config)

        raise "The 'config' parameter must be of '" + Config.to_s + "' data type"
      end

      @config = config
    end

    if connector == nil

      @connector = HarnessConnector.new(api_key, config = @config, on_unauthorized = self)

    else

      unless connector.kind_of?(Connector)

        raise "The 'connector' parameter must be of '" + Connector.to_s + "' data type"
      end

      @connector = connector
    end

    @closing = false
    @failure = false
    @initialized = false
    @poller_ready = false
    @stream_ready = false
    @metric_ready = false

    @my_mutex = Mutex.new

    @repository_callback = InnerClientRepositoryCallback.new

    setup
  end

  def bool_variation(identifier, target, default_value)

    @evaluator.bool_variation(identifier, target, default_value, @evaluator_callback)
  end

  def string_variation(identifier, target, default_value)

    @evaluator.string_variation(identifier, target, default_value, @evaluator_callback)
  end

  def number_variation(identifier, target, default_value)

    @evaluator.number_variation(identifier, target, default_value, @evaluator_callback)
  end

  def json_variation(identifier, target, default_value)

    @evaluator.json_variation(identifier, target, default_value, @evaluator_callback)
  end

  def on_auth_success

    puts "SDK successfully logged in"

    if @closing

      return
    end

    @poll_processor.start

    if @config.stream_enabled

      @update_processor.start
    end

    if @config.analytics_enabled

      @metrics_processor.start
    end

  end

  def close

    puts "Closing the client: " + self.to_s

    @closing = true

    off

    @auth_service.close
    @repository.close
    @poll_processor.close
    @update_processor.close
    @metrics_processor.close
    @connector.close
  end

  def is_closing

    @closing
  end

  def off

    # TODO: Implement
  end

  def on_unauthorized

    if @closing

      return
    end

    @poll_processor.stop

    if @config.stream_enabled

      @update_processor.stop
    end

    if @config.analytics_enabled

      @metrics_processor.stop
    end

    @auth_service.start_async
  end

  def on_poller_ready(poller)

    on_processor_ready(poller)
  end

  def on_poller_error(e)

    puts "Poller error: " + e.to_s
  end

  def on_poller_iteration(poller)

    puts "Poller iterated" + poller.to_s
  end

  def update(message, manual)

    if @config.stream_enabled && manual

      puts "You run the update method manually with the stream enabled. Please turn off the stream in this case."
    end

    @update_processor.update(message)
  end

  def on_update_processor_ready

    on_processor_ready(@update_processor)
  end

  def on_processor_ready(processor)

    if @closing

      return
    end

    if processor == @poll_processor

      @poller_ready = true
      puts "PollingProcessor ready"
    end

    if processor == @update_processor

      @stream_ready = true
      puts "Updater ready"
    end

    if (@config.stream_enabled && !@stream_ready) ||
      (@config.analytics_enabled && !@metric_ready) ||
      !@poller_ready

      return
    end

    @initialized = true

    # TODO: notify
    # TODO: notify_consumers

    puts "Initialization is completed"
  end

  def wait_for_initialization

    synchronize do

      puts "Waiting for the initialization to finish"

      until @initialized

        sleep(1)
      end

      if @failure

        raise "Initialization failed"
      end

      puts "Waiting for the initialization completed"
    end
  end

  protected

  def setup

    puts "SDK is not initialized yet! If store is used then values will be loaded from store \n" +
           " otherwise default values will be used in meantime. You can use waitForInitialization method for SDK" +
           " to be ready."

    @repository = StorageRepository.new(@config.cache, @config.store, @repository_callback)

    @metrics_callback = InnerClientMetricsCallback.new
    @metrics_processor = MetricsProcessor.new(@connector, @config, @metrics_callback)

    @evaluator = Evaluator.new(@repository)
    @evaluator_callback = InnerClientFlagEvaluateCallback.new(@metrics_processor)

    @auth_service = AuthService.new(

      connector = @connector,
      poll_interval_in_sec = @config.poll_interval_in_seconds,
      callback = self
    )

    @poll_processor = PollingProcessor.new(

      connector = @connector,
      repository = @repository,
      poll_interval_in_sec = @config.poll_interval_in_seconds,
      callback = self
    )

    @updater = InnerClientUpdater.new(

      poll_processor = @poll_processor,
      client_callback = self
    )

    @update_processor = UpdateProcessor.new(

      connector = @connector,
      repository = @repository,
      callback = @updater
    )

    @auth_service.start_async
  end

  private

  def synchronize(&block)

    @my_mutex.synchronize(&block)
  end
end
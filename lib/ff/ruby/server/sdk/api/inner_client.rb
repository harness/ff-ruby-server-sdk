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
require_relative "../common/sdk_codes"

class InnerClient < ClientCallback

  def initialize(api_key = nil, config = nil, connector = nil)

    if api_key == nil || api_key == ""
      SdkCodes::raise_missing_sdk_key config.logger
    end

    if config == nil

      @config = ConfigBuilder.new.build
    else

      unless config.kind_of?(Config)

        raise "The 'config' parameter must be of '" + Config.to_s + "' data type"
      end

      @config = config
    end

    @config.logger.debug "Ruby SDK version: " + Ff::Ruby::Server::Sdk::VERSION

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
    @metrics_ready = false

    @my_mutex = Mutex.new

    @repository_callback = InnerClientRepositoryCallback.new(@config.logger)

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

    SdkCodes::info_sdk_auth_ok @config.logger

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

  def on_auth_failed
    SdkCodes::warn_auth_failed_srv_defaults @config.logger
    @initialized = true
  end

  def close

    @config.logger.info "Closing the client: " + self.to_s

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

    # TODO: Implement - Reactivity support
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

    @config.logger.error "Poller error: " + e.to_s
  end

  def on_poller_iteration(poller)

    @config.logger.debug "Poller iterated" + poller.to_s
  end

  def update(message, manual)

    if @config.stream_enabled && manual

      @config.logger.warn "You run the update method manually with the stream enabled. Please turn off the stream in this case."
    end

    @update_processor.update(message)
  end

  def on_update_processor_ready

    on_processor_ready(@update_processor)
  end

  def on_metrics_processor_ready

    on_processor_ready(@metrics_processor)
  end

  def on_processor_ready(processor)

    if @closing

      return
    end

    if processor == @poll_processor

      @poller_ready = true
      @config.logger.debug "PollingProcessor ready"
    end

    if processor == @update_processor

      @stream_ready = true
      @config.logger.debug "Updater ready"
    end

    if processor == @metrics_processor

      @metrics_ready = true
      @config.logger.debug "Metrics ready"
    end

    if (@config.stream_enabled && !@stream_ready) ||
      (@config.analytics_enabled && !@metrics_ready) ||
      !@poller_ready

      return
    end

    SdkCodes.info_sdk_init_ok @config.logger

    @initialized = true
  end

  def wait_for_initialization(timeout: nil)
    synchronize do
      SdkCodes::info_sdk_waiting_to_initialize(@config.logger, timeout)

      start_time = Time.now

      until @initialized
        # Check if a timeout is specified and has been exceeded
        if timeout && (Time.now - start_time) > (timeout / 1000.0)
          @config.logger.warn "The SDK has timed out waiting to initialize with supplied timeout #{timeout} ms"
          handle_initialization_failure
        end

        sleep(1)
      end

      if @failure
        raise "Initialization failed"
      end

      @config.logger.debug "Waiting for initialization has completed"
    end
  end


  protected

  def handle_initialization_failure
    @auth_service.close
    @poll_processor.stop
    @update_processor.stop
    @metrics_processor.stop
    on_auth_failed
  end

  def setup

    @repository = StorageRepository.new(@config.cache, @repository_callback, @config.store, @config.logger)

    @metrics_callback = InnerClientMetricsCallback.new(self, @config.logger)
    @metrics_processor = MetricsProcessor.new
    @metrics_processor.init(@connector, @config, @metrics_callback)

    @evaluator = Evaluator.new(@repository, logger = @config.logger)

    if @config.analytics_enabled
      @evaluator_callback = InnerClientFlagEvaluateCallback.new(@metrics_processor, logger = @config.logger)
    end

    @auth_service = AuthService.new(
      connector = @connector,
      callback = self,
      logger = @config.logger
    )

    @poll_processor = PollingProcessor.new
    @poll_processor.init(
      connector = @connector,
      repository = @repository,
      poll_interval_in_sec = @config.poll_interval_in_seconds,
      callback = self,
      logger = @config.logger
    )

    @updater = InnerClientUpdater.new(

      poll_processor = @poll_processor,
      client_callback = self,
      logger = @config.logger
    )

    @update_processor = UpdateProcessor.new
    @update_processor.init(

      connector = @connector,
      repository = @repository,
      callback = @updater,
      logger = @config.logger
    )

    @auth_service.start_async
  end

  private

  def synchronize(&block)

    @my_mutex.synchronize(&block)
  end

end
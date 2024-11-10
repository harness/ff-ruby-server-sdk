require_relative "metrics_processor"
require_relative "flag_evaluate_callback"

class InnerClientFlagEvaluateCallback < FlagEvaluateCallback

  def initialize(metrics_processor, logger = nil)

    unless metrics_processor.kind_of?(MetricsProcessor)

      raise "The 'metrics_processor' parameter must be of '" + MetricsProcessor.to_s + "' data type"
    end

    if logger != nil

      @logger = logger
    else

      @logger = Logger.new(STDOUT)
    end

    @metrics_processor = metrics_processor
  end

  def process_evaluation(feature_config:, target:, variation:)

    @logger.debug "Processing evaluation: " + feature_config.feature.to_s + ", " + target.identifier.to_s

    @metrics_processor.register_evaluation(target: target, feature_config: feature_config, variation: variation)
  end
end
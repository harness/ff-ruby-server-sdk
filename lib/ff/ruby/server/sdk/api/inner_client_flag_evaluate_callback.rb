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

  def process_evaluation(feature_name, target, variation_identifier)

    @logger.debug "Processing evaluation: #{feature_name || 'nil feature'}, #{variation_identifier || 'nil variation'},  #{target&.identifier || 'nil target'}"

    @metrics_processor.register_evaluation(target, feature_name, variation_identifier)
  end
end
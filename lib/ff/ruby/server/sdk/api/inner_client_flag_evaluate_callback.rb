require_relative "metrics_processor"
require_relative "flag_evaluate_callback"

class InnerClientFlagEvaluateCallback < FlagEvaluateCallback

  def initialize(metrics_processor)

    unless metrics_processor.kind_of?(MetricsProcessor)

      raise "The 'metrics_processor' parameter must be of '" + MetricsProcessor.to_s + "' data type"
    end

    @metrics_processor = metrics_processor
  end

  def process_evaluation(feature_config, target, variation)

    puts "Processing evaluation: " + feature_config.feature.to_s + ", " + target.identifier.to_s

    @metrics_processor.push_to_queue(target, feature_config, variation)
  end
end
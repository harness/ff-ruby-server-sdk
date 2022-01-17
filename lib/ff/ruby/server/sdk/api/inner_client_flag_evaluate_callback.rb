require_relative "flag_evaluate_callback"

class InnerClientFlagEvaluateCallback < FlagEvaluateCallback

  # TODO: Initialize with metrics

  def process_evaluation(feature_config, target, variation)

    puts "Processing evaluation: " + feature_config.feature.to_s + ", " + target.identifier.to_s

    # TODO: Metrics
  end
end
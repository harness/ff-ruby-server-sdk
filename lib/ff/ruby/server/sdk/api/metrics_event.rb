class MetricsEvent

  def initialize(

    feature_config,
    target,
    variation
  )

    @target = target
    @variation = variation
    @feature_config = feature_config
  end
end
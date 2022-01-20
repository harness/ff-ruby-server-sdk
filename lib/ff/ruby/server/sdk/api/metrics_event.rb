class MetricsEvent

  def initialize(

    feature_config,
    target,
    variation
  )

    @feature_config = feature_config
    @target = target
    @variation = variation
  end
end
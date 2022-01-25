class MetricsEvent

  attr_accessor :feature_config, :target, :variation

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
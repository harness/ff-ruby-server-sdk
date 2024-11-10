class MetricsEvent

  attr_accessor :feature_config, :target, :variation

  def initialize(feature_config:, target:, variation:)
    @feature_config = feature_config
    @target = target
    @variation = variation
    freeze
  end

  def ==(other)
    eql?(other)
  end

  def eql?(other)
    unless other.is_a?(MetricsEvent)
      @logger.warn("Warning: Attempted to compare MetricsEvent with #{other.class.name}" )
      return false
    end

    feature_config.feature == other.feature_config.feature &&
      variation.identifier == other.variation.identifier &&
      target.identifier == other.target.identifier
  end

  def hash
    [feature_config.feature, variation.identifier, target.identifier].hash
  end



end
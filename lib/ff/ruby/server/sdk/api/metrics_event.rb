class MetricsEvent

  attr_accessor :feature_config, :target, :variation

  def initialize(feature_config, target, variation, logger)

    @target = target
    @variation = variation
    @feature_config = feature_config
    @logger = logger
    freeze
  end

  def ==(other)
    eql?(other)
  end

  def eql?(other)
    # Guard clause other is the same type.
    # While it should be, this adds protection for an edge case we are seeing with very large
    # project sizes. Issue being tracked in FFM-12192, and once resolved, can feasibly remove
    # these checks in a future release.
    unless other.is_a?(MetricsEvent)
      # We should always have a logger available except when we've deep cloned this class.  We don't do any
      # equality check on clones in metrics code anyway, so this is just a safety check.
      if @logger
        @logger.warn("Warning: Attempted to compare MetricsEvent with #{other.class.name}")
      end
      return false
    end

    feature_config.feature == other.feature_config.feature and
      variation.identifier == other.variation.identifier and
      target.identifier == other.target.identifier
  end

  def hash
    feature_config.feature.hash | variation.identifier.hash | target.identifier.hash
  end


  # Exclude logger from serialization
  def marshal_dump
    [@feature_config, @target, @variation]
  end

  def marshal_load(array)
    @feature_config, @target, @variation = array
    @logger = nil
  end


end
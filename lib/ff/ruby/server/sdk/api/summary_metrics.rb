class SummaryMetrics

  attr_accessor :feature_name, :variation_identifier, :variation_value

  def initialize(

    feature_name,
    variation_identifier,
    variation_value
  )

    @feature_name = feature_name
    @variation_value = variation_value
    @variation_identifier = variation_identifier
  end
end
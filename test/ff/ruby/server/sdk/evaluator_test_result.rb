class EvaluatorTestResult

  attr_accessor :file, :target_identifier, :value, :use_case

  def initialize(

    file,
    target_identifier,
    value,
    use_case
  )

    @file = file
    @value = value
    @use_case = use_case
    @target_identifier = target_identifier
  end
end
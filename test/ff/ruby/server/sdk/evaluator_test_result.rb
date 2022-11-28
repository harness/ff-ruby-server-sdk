class EvaluatorTestResult

  attr_accessor :file, :target_identifier, :value, :use_case

  def initialize(

    file,
    flag,
    target_identifier,
    value,
    use_case
  )

    @file = file
    @flag = flag
    @value = value
    @use_case = use_case
    @target_identifier = target_identifier
  end
end
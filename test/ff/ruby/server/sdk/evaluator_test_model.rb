class EvaluatorTestModel

  attr_writer :test_file, :flag, :targets, :segments, :expected

  def initialize(

    test_file,
    flag,
    targets,
    segments,
    expected
  )

    @flag = flag
    @targets = targets
    @segments = segments
    @expected = expected
    @test_file = test_file
  end
end
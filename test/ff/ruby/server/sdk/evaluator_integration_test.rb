require_relative "evaluator_tester"
require_relative "evaluator_test_model"

class EvaluatorIntegrationTest < Minitest::Test

  def execute

    @tester = EvaluatorTester.new
    @test_data = []

    puts "The evaluator integration test: START"

    refute_nil @tester
    refute_nil @test_data



    puts "The evaluator integration test: END"
    true
  end

end
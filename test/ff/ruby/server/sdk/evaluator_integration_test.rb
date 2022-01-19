require_relative "evaluator_tester"
require_relative "evaluator_test_model"

class EvaluatorIntegrationTest < Minitest::Test

  def execute

    @tester = EvaluatorTester.new
    @test_data = prepare_test_data

    puts "The evaluator integration test: START"

    refute_nil @tester
    refute_nil @test_data

    @test_data.each do |data|

      unless @tester.process(data)

        return false
      end
    end

    puts "The evaluator integration test: END"
    true
  end

  private

  def prepare_test_data

    raise "Not implemented"
  end

end
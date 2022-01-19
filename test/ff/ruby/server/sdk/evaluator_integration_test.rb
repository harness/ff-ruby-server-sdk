require_relative "evaluator_tester"
require_relative "evaluator_test_model"

class EvaluatorIntegrationTest < Minitest::Test

  def execute

    @tester = EvaluatorTester.new
    @test_data = prepare_test_data

    msg = "The evaluator integration test: "

    puts msg + "START"

    refute_nil @tester
    refute_nil @test_data

    @test_data.each do |data|

      puts msg +  "Processing: " + data.to_s

      unless @tester.process(data)

        puts msg + "Failed: " + data.to_s

        return false
      end
    end

    puts msg + "END"
    true
  end

  private

  def prepare_test_data

    @tests_location = Dir.pwd + "/test/cases/tests"

    @files = Dir.children(@tests_location)

    refute_nil @files

    assert !@files.empty?

    @test_data = []

    @files.each do |file|

      refute_nil file

      assert file.end_with?(".json")

      puts "Loading the mock data file: " + file.to_s

      the_file = File.new(@tests_location + "/" + file, "r")

      if the_file

        data = File.read(the_file.path)

        refute_nil data

        assert !data.empty?



      else

        puts "Not able to access the file: " + file.to_s
      end

    end
  end

end
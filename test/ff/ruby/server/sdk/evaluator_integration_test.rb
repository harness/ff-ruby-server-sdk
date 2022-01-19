require "json"

require_relative "evaluator_tester"

class EvaluatorIntegrationTest < Minitest::Test

  def execute

    @tester = EvaluatorTester.new("Evaluator_Tester")
    prepare_test_data

    msg = "The evaluator integration test: "

    puts msg + "START"

    refute_nil @tester
    refute_nil @test_data

    @test_data.each do |data|

      unless @tester.process(data)

        puts msg + "Failed: " + data["test_file"].to_s

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

        model = JSON.parse(data)

        refute_nil model

        model["test_file"] = file

        feature = (model["flag"]["feature"].to_s + file).gsub("_", "").gsub(".", "").downcase

        model["flag"]["feature"] = feature

        @test_data.push(model)

        assert !@test_data.empty?

      else

        puts "Not able to access the file: " + file.to_s
      end
    end
  end

end
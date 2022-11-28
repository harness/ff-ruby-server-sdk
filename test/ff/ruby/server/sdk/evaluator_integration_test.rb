require "json"

require_relative "evaluator_tester"

class EvaluatorIntegrationTest < Minitest::Test

  $tester
  $test_data = []

  def initialize(name)
    super(name)
    $tester = EvaluatorTester.new("Evaluator_Tester")
    load_test_fixtures
  end

  def execute

    msg = "The evaluator integration test: "

    puts msg + "START"

    refute_nil $tester
    refute_nil $test_data


    describe "ff-test-grid" do
      $test_data.each do |data|
        it "#{data["filename"]}" do
          unless $tester.process(data)
            puts msg + "Failed: " + data["test_file"].to_s
            return false
          end
        end
      end
    end

    puts msg + "END"
    true
  end

  private

  def load_test_fixtures

    @tests_location = Dir.pwd + "/test/cases/tests/"
    
    @files = []
    Dir.glob(@tests_location + "**/*") do |file|
      if file.end_with?(".json")
        @files.append(file.delete_prefix(@tests_location))
      end
    end

    refute_nil @files

    assert !@files.empty?

    @files.each do |file|

      refute_nil file

      assert file.end_with?(".json")

      puts "Loading the mock data file: " + file.to_s

      the_file = File.new(@tests_location + "/" + file, "r")

      if the_file

        data = File.read(the_file.path)
        refute_nil data
        assert !data.empty?
        models = JSON.parse(data)
        refute_nil models

        models["filename"] = file.to_s
        $test_data.push(models)
        assert !$test_data.empty?
      else
        puts "Not able to access the file: " + file.to_s
      end
    end

  end
end

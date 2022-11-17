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

        models = JSON.parse(data)

        refute_nil models

        models["flags"] = [models["flag"]] if models["flags"].to_a.empty?

        models["flags"].each do |flag_data|
          model = {}
          model["flag"] = flag_data
          model["test_file"] = file
          model["tests"] = models["tests"] unless models["tests"].nil?
          model["expected"] = models["expected"] unless models["expected"].nil?

          feature = (model["flag"]["feature"].to_s + file).gsub("_", "").gsub(".", "").downcase

          model["flag"]["feature"] = feature

          flag_hash = model["flag"]

          refute_nil flag_hash

          flag_hash["default_serve"] = OpenapiClient::Serve.new(flag_hash["defaultServe"])
          flag_hash.delete("defaultServe")

          dist = flag_hash["default_serve"].distribution

          if dist != nil

            flag_hash["default_serve"].distribution = OpenapiClient::Distribution.new(dist)
          end

          flag_hash["off_variation"] = flag_hash["offVariation"]
          flag_hash.delete("offVariation")

          flag_hash["variation_to_target_map"] = flag_hash["variationToTargetMap"]
          flag_hash.delete("variationToTargetMap")

          flag_hash["state"] = OpenapiClient::FeatureState.build_from_hash(flag_hash["state"])

          variations = []

          flag_hash["variations"].each do |v|

            variation = OpenapiClient::Variation.new(v)

            refute_nil variation

            variations.push(variation)

            assert !variations.empty?
          end

          flag_hash["variations"] = variations

          rules = []

          flag_hash["rules"].each do |v|

            refute_nil v

            v["rule_id"] = v["ruleId"]
            v.delete("ruleId")

            clauses = []

            if v["clauses"] != nil

              v["clauses"].each do |c|

                clause = OpenapiClient::Clause.new(c)

                refute_nil clause

                clauses.push(clause)

                assert !clauses.empty?
              end
            end

            v["clauses"] = clauses

            v["serve"] = OpenapiClient::Serve.new(v["serve"])

            rule = OpenapiClient::ServingRule.new(v)

            refute_nil rule

            rules.push(rule)

            assert !rules.empty?
          end

          flag_hash["rules"] = rules

          prerequisites = []

          flag_hash["prerequisites"].each do |v|

            prerequisite = OpenapiClient::Prerequisite.new(v)

            refute_nil prerequisite

            prerequisites.push(prerequisite)

            assert !prerequisites.empty?
          end

          flag_hash["prerequisites"] = prerequisites

          variation_to_target_map = []

          if flag_hash["variation_to_target_map"] != nil

            flag_hash["variation_to_target_map"].each do |v|

              refute_nil v

              v["target_segments"] = v["targetSegments"]
              v.delete("targetSegments")

              map = OpenapiClient::VariationMap.new(v)

              refute_nil map

              variation_to_target_map.push(map)

              assert !variation_to_target_map.empty?
            end
          end

          flag_hash["variation_to_target_map"] = variation_to_target_map

          flag = OpenapiClient::FeatureConfig.new(flag_hash)

          refute_nil flag

          model["flag"] = flag

          @test_data.push(model)

          assert !@test_data.empty?
        end
      else

        puts "Not able to access the file: " + file.to_s
      end
    end
  end
end

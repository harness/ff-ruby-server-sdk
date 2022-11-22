require "json"

require_relative "evaluator_test_result"

class EvaluatorTester < Minitest::Test

  def process(data)

    @results = []
    @no_target = "_no_target"
    @cache = DefaultCache.new
    @repository = StorageRepository.new(@cache)
    @evaluator = Evaluator.new(@repository)

    puts "Processing the test data '" + data["filename"].to_s + "' started"


    data["flags"]&.each do |flag_hash|
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

      flag_hash["rules"]&.each do |v|

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

      flag_hash["prerequisites"]&.each do |v|

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

          # Convert the target JSON to target object
          vTargets = v["targets"]
          v.delete("targets")
          v["targets"] = []
          vTargets&.each do |t|
            v["targets"].append(OpenapiClient::Target.new(t))
          end



          map = OpenapiClient::VariationMap.new(v)

          refute_nil map

          variation_to_target_map.push(map)

          assert !variation_to_target_map.empty?
        end
      end

      flag_hash["variation_to_target_map"] = variation_to_target_map

      f = OpenapiClient::FeatureConfig.new(flag_hash)

      refute_nil f

      @repository.set_flag(f.feature.to_s, f)
    end


    segments = data["segments"]
    if segments != nil

      segments.each do |segment_hash|

        puts "Segment: " + segment_hash.to_s

        excluded_segments = []
        included_segments = []

        if segment_hash["included"] != nil

          segment_hash["included"].each do |v|

            t = OpenapiClient::Target.new(v)

            refute_nil t
            included_segments.push(t)
            assert !included_segments.empty?
          end
        end

        if segment_hash["excluded"] != nil

          segment_hash["excluded"].each do |v|

            t = OpenapiClient::Target.new(v)

            refute_nil t
            excluded_segments.push(t)
            assert !excluded_segments.empty?
          end
        end

        segment_hash["included"] = included_segments
        segment_hash["excluded"] = excluded_segments

        rules = []
        if segment_hash["rules"] != nil
          segment_hash["rules"]&.each do |r|
            clause = OpenapiClient::Clause.new(r)
            refute_nil clause
            rules.push(clause)
          end
          segment_hash["rules"] = rules
        end

        segment = OpenapiClient::Segment.new(segment_hash)

        refute_nil segment

        @repository.set_segment(segment.identifier, segment)
      end
    end

    if data["tests"] != nil
      data["tests"].each do |test|

        target = test["target"].nil? ? "_no_target" : test["target"]
        value = test["expected"]

        puts "Expected: " + target.to_s + " -> " + value.to_s + "for flag " + test["flag"]

        data["flag"] = @repository.get_flag(test["flag"].to_s)

        result = EvaluatorTestResult.new(
          data["filename"],
          test["flag"],
          target,
          value,
          data,
        )

        refute_nil result

        @results.push(result)
      end
    end

    assert !@results.empty?

    @results.each do |result|

      refute_nil result

      puts "Use case '" + result.use_case["flag"].to_s + "' with target '" + result.target_identifier.to_s + "' and expected value '" + result.value.to_s + "'"

      target = nil

      if @no_target != result.target_identifier

        if result.use_case["targets"] != nil

          result.use_case["targets"].each do |item|

            if item != nil && item["identifier"] == result.target_identifier

              target = OpenapiClient::Target.new(item)
              break
            end
          end
        end
      end

      kind = result.use_case["flag"].kind

      refute_nil kind

      case kind

      when "boolean"

        received = @evaluator.bool_variation(

          result.use_case["flag"].feature,
          target,
          false,
          nil
        )
      when "int"

        received = @evaluator.number_variation(

          result.use_case["flag"].feature,
          target,
          0,
          nil
        )

      when "string"

        received = @evaluator.string_variation(

          result.use_case["flag"].feature,
          target,
          "",
          nil
        )

      when "json"

        received = @evaluator.json_variation(

          result.use_case["flag"].feature,
          target,
          JSON.parse("{}"),
          nil
        )

      else

        raise "Unrecognized kind: " + kind.to_s
      end

      refute_nil received

      puts "Comparing: '" + result.value.to_s + "' to '" + received.to_s + "'"

      return result.value == received
    end

    puts "Processing the test data '" + data["test_file"].to_s + "' completed"
    true
  end

end

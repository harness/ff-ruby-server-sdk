require_relative "evaluator_test_result"

class EvaluatorTester < Minitest::Test

  def process(data)

    @no_target = "_no_target"

    cache = DefaultCache.new

    @repository = StorageRepository.new(cache, nil, nil)

    @results = []
    @evaluator = Evaluator.new(@repository)

    puts "Processing the test data '" + data["test_file"].to_s + "' started"

    flag_hash = data["flag"]

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

    @repository.set_flag(flag.feature.to_s, flag)

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

        segment = OpenapiClient::Segment.new(segment_hash)

        refute_nil segment

        @repository.set_segment(segment.identifier, segment)
      end
    end

    data["expected"].each do |key, value|

      puts "Expected: " + key.to_s + " -> " + value.to_s

      expected = data["expected"][key]

      result = EvaluatorTestResult.new(

        data["test_file"],
        key,
        expected,
        data
      )

      refute_nil result

      @results.push(result)
    end

    assert !@results.empty?

    @results.each do |result|

      refute_nil result

      "Use case '" + result.file.to_s + "' with target '" + result.target_identifier.to_s + "' and expected value '" +
        result.value.to_s + "'"

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

      received = nil
      kind = result.use_case["flag"]["kind"]

      refute_nil kind

      case kind

      when "boolean"
        received = @evaluator.bool_variation(

          result.use_case["flag"]["feature"],
          target,
          false,
          nil
        )
      when "int"

      when "string"

      when "json"

      else
        raise "Unrecognized kind: " + kind.to_s
      end

    end

    puts "Processing the test data '" + data["test_file"].to_s + "' completed"

    true
  end
end
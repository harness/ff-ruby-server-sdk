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

    flag_hash["default_serve"] = flag_hash["defaultServe"]
    flag_hash.delete("defaultServe")

    flag_hash["off_variation"] = flag_hash["offVariation"]
    flag_hash.delete("offVariation")

    flag_hash["variation_to_target_map"] = flag_hash["variationToTargetMap"]
    flag_hash.delete("variationToTargetMap")

    flag = OpenapiClient::FeatureConfig.new(flag_hash)

    refute_nil flag

    @repository.set_flag(flag.feature.to_s, flag)

    segments = data["segments"]

    if segments != nil

      segments.each do |segment_hash|

        puts "Segment: " + segment_hash.to_s

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

    end

    puts "Processing the test data '" + data["test_file"].to_s + "' completed"

    true
  end
end
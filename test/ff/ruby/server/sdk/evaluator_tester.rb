require "json"

require_relative "evaluator_test_result"

class EvaluatorTester < Minitest::Test

  def process(data)

    @no_target = "_no_target"

    cache = DefaultCache.new

    @repository = StorageRepository.new(cache, nil, nil)

    @results = []
    @evaluator = Evaluator.new(@repository)

    puts "Processing the test data '" + data["test_file"].to_s + "' started"

    flag = data["flag"]

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


    end

    puts "Processing the test data '" + data["test_file"].to_s + "' completed"

    true
  end
end
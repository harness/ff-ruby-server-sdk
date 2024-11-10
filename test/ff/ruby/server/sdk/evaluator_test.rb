require "minitest/autorun"
require "ff/ruby/server/sdk/common/repository"
require "ff/ruby/server/sdk/api/default_cache"
require "ff/ruby/server/sdk/api/storage_repository"
require "ff/ruby/server/sdk/api/evaluator"
require "ff/ruby/server/sdk/dto/target"
require "ff/ruby/server/generated/lib/openapi_client/models/feature_config"
require "ff/ruby/server/generated/lib/openapi_client/models/feature_state"
require "ff/ruby/server/generated/lib/openapi_client/models/segment"
require "ff/ruby/server/generated/lib/openapi_client/models/variation"
require "ff/ruby/server/generated/lib/openapi_client/models/distribution"
require "ff/ruby/server/generated/lib/openapi_client/models/serve"
require "ff/ruby/server/generated/lib/openapi_client/models/variation_map"
require "ff/ruby/server/generated/lib/openapi_client/models/clause"
require "ff/ruby/server/generated/lib/openapi_client/models/group_serving_rule"
require 'json'

class EvaluatorTest < Minitest::Test

  [
    #
    # if (target.attr.email endswith '@harness.io' && target.attr.role = 'developer')
    #
    { name: "email_is_dev", email: "user@harness.io", role: "developer", expected: true },
    { name: "email_is_mgr", email: "user@harness.io", role: "manager", expected: false },
    { name: "external_email_is_dev", email: "user@gmail.com", role: "developer", expected: false },
    { name: "external_email_is_mgr", email: "user@gmail.com", role: "manager", expected: false },

  ].each do |test_case|

    define_method("test_target_v2_and_operator__#{test_case[:name]}") do
      flag_name = "boolflag_and"

      cache = DefaultCache.new
      repo = StorageRepository.new cache
      load_flags repo, "#{__dir__}/local-test-cases/v2-andor-flags.json"
      load_segments repo, "#{__dir__}/local-test-cases/v2-andor-segments.json"
      evaluator = Evaluator.new repo

      target = Target.new(identifier: "test", attributes: { "email": test_case[:email], "role": test_case[:role] })
      result = evaluator.evaluate(identifier: flag_name, target: target, expected: "boolean", callback: nil)
      assert_equal test_case[:expected].to_s, result.value
    end
  end

  [
    #
    # if (target.attr.email endswith '@harness.io' || target.attr.email endswith '@somethingelse.com'
    #
    { name: "email_is_harness", email: "user@harness.io", role: "developer", expected: true },
    { name: "email_is_something_else", email: "user@somethingelse.com", role: "manager", expected: true },
    { name: "email_is_gmail", email: "user@gmail.com", role: "developer", expected: false },

  ].each do |test_case|

    define_method("test_target_v2_or_operator__#{test_case[:name]}") do
      flag_name = "boolflag_or"

      cache = DefaultCache.new
      repo = StorageRepository.new cache
      load_flags repo, "#{__dir__}/local-test-cases/v2-andor-flags.json"
      load_segments repo, "#{__dir__}/local-test-cases/v2-andor-segments.json"
      evaluator = Evaluator.new repo

      target = Target.new(identifier: "test", name: "test", attributes: { "email": test_case[:email], "role": test_case[:role] })
      result = evaluator.evaluate(identifier: flag_name, target: target, expected: "boolean", callback: nil)
      assert_equal test_case[:expected].to_s, result.value
    end
  end

  def load_flags repo, json_file
    loaded = JSON.load File.new(json_file), nil, { symbolize_names: true, create_additions: false }
    loaded.each do |flag_json|

      klass = OpenapiClient.const_get('FeatureConfig')
      flag = klass.respond_to?(:openapi_one_of) ? klass.build(flag_json) : klass.build_from_hash(flag_json)

      repo.set_flag(flag.feature, flag)
    end
  end

  def load_segments repo, json_file
    loaded = JSON.load File.new(json_file), nil, { symbolize_names: true, create_additions: false }
    loaded.each do |segment_json|

      klass = OpenapiClient.const_get('Segment')
      segment = klass.respond_to?(:openapi_one_of) ? klass.build(segment_json) : klass.build_from_hash(segment_json)

      repo.set_segment(segment.identifier, segment)
    end
  end

end
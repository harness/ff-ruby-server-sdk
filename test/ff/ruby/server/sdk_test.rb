# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ff/ruby/server/sdk"
require "minitest/autorun"

class Ff::Ruby::Server::SdkTest < Minitest::Test

  def test_version_number

    refute_nil ::Ff::Ruby::Server::Sdk::VERSION
  end

  def test_instantiation

    instance = CfClient.instance
    (0..5).each {

      compare_equal = CfClient.instance
      compare_not_equal = CfClient.new

      assert_equal(instance.to_s, compare_equal.to_s)
      assert(instance.to_s != compare_not_equal.to_s)
    }
  end
end

# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ff/ruby/server/sdk"
require "minitest/autorun"

class Ff::Ruby::Server::ClientInstantiationTest < Minitest::Test

  def test_version_number

    refute_nil ::Ff::Ruby::Server::Sdk::VERSION
  end

  def test_singleton_instantiation

    instance = CfClient.instance
    (0..5).each {

      compare_equal = CfClient.instance
      assert_equal(instance, compare_equal)
    }
  end

  def test_constructor_instantiation

    test_string = "test"
    instance_with = Client.new(test_string)
    instance_with_no_config = Client.new(test_string, test_string)

    assert(instance_with != nil)
    assert(instance_with_no_config != nil)
    assert(instance_with != instance_with_no_config)
  end
end

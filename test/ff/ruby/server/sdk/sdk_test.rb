# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ff/ruby/server/sdk"
require "minitest/autorun"

class Ff::Ruby::Server::SdkTest < Minitest::Test

  def test_version_number

    refute_nil ::Ff::Ruby::Server::Sdk::VERSION
  end

  def test_client_singleton_inst

    instance = CfClient.instance
    (0..5).each {

      compare_equal = CfClient.instance
      assert_equal(instance, compare_equal)
    }
  end

  def test_client_constructor_inst

    test_string = "test"
    instance_with = Client.new(test_string)
    instance_with_no_config = Client.new(test_string, test_string)

    assert(instance_with != nil)
    assert(instance_with_no_config != nil)
    assert(instance_with != instance_with_no_config)
  end

  def test_config_constructor_inst

    config = Config.new
    config_not_equal = Config.new

    assert(config != nil)
    assert(config_not_equal != nil)
    assert(config != config_not_equal)
  end
end

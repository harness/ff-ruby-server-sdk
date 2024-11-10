require "minitest/autorun"
require "ff/ruby/server/sdk/dto/target"

class TargetTest < Minitest::Test
  def test_various_target_attrs
    target = Target.new(identifier: "test", name:"test")
    assert_equal 0, target.attributes.size

    target = Target.new(name:"test", identifier:"test", attributes: {} )
    assert_equal 0, target.attributes.size

    target = Target.new(name:"test", identifier:"test", )
    assert_equal 0, target.attributes.size

    target = Target.new(name:"test", identifier:"test", attributes: {test: "this_is_a_symbol_key"})
    assert_equal 1, target.attributes.size
    assert target.attributes[:test]

    target = Target.new(name:"test", identifier:"test",attributes: {"test": "this_is_a_string_key"})
    assert_equal 1, target.attributes.size
    assert target.attributes[:test]
  end
end
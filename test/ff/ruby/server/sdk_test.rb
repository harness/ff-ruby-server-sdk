# frozen_string_literal: true

require "test_helper"

class Ff::Ruby::Server::SdkTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Ff::Ruby::Server::Sdk::VERSION
  end

  def test_it_does_something_useful
    assert false
  end
end

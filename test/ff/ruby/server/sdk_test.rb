# frozen_string_literal: true

require_relative "../../../test_helper"

class Ff::Ruby::Server::SdkTest < Minitest::Test

  def test_version_number
    refute_nil ::Ff::Ruby::Server::Sdk::VERSION
  end
end

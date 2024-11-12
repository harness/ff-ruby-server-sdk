require "minitest/autorun"
require "ff/ruby/server/sdk/api/config"
require "ff/ruby/server/sdk/dto/target"
require "ff/ruby/server/sdk/api/cf_client"
require "ff/ruby/server/sdk/api/config_builder"
require "logger"
require "securerandom"
require 'json'
require 'socket'

class CfClientTest < Minitest::Test

  [401,403,404,408,425,429,500,502,503,504].each do |http_code|
    define_method("test_serve_defaults_on_no_auth_#{http_code}") do

      logger = Logger.new(STDOUT)
      logger.level = Logger::DEBUG
      logger.info "---------- TEST #{__method__} ----------"

      port = rand(1000..9999)
      Thread.new {
        logger.info "listening on #{port}"
        TCPServer.open("localhost", port) { |serve|
          client = serve.accept
          client.puts "HTTP/1.1 #{http_code} dummy http message"
          client.puts
          client.close
        }
        Thread.current.terminate
      }

      client = CfClient.instance

      client.init("DUMMY_KEY", ConfigBuilder.new.logger(logger)
                                            .stream_enabled(false)
                                            .analytics_enabled(false)
                                            .event_url("http://localhost:#{port}/api/1.0")
                                            .config_url("http://localhost:#{port}/api/1.0").build)

      client.wait_for_initialization(timeout_ms: 5000)

      target = Target.new("RubyTestSDK", identifier="rubytestsdk", attributes={"location": "emea"})

      # assert that we get default values, even if we're still authenticating
      [1..100].each do |n|
        assert client.bool_variation("DUMMY_BOOL_FLAG", target, true)
        assert !client.bool_variation("DUMMY_BOOL_FLAG", target, false)
        assert_equal "STR1", client.string_variation("DUMMY_STR_FLAG", target, "STR1")
        assert_equal "STR2", client.string_variation("DUMMY_STR_FLAG", target, "STR2")
        assert_equal 123, client.string_variation("DUMMY_STR_FLAG", target, 123)
        assert_equal 321, client.string_variation("DUMMY_STR_FLAG", target, 321)
        assert_equal JSON.parse('{"test":"123"}'), client.json_variation("DUMMY_STR_FLAG", target, JSON.parse('{"test":"123"}'))
        assert_equal JSON.parse('{"test":"321"}'), client.json_variation("DUMMY_STR_FLAG", target, JSON.parse('{"test":"321"}'))
      end
    end
  end


end
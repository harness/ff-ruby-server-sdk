require "minitest/autorun"
require "ff/ruby/server/sdk"
require "concurrent/atomics"

class AuthServiceTest < Minitest::Test

  class ReturnHttpCodeConnector < Connector
    def initialize(http_code)
      @http_code = http_code
    end
    def authenticate
      puts "got auth, return with http code #{@http_code}"
      @http_code
    end
  end

  class FailThenRecoverConnector < Connector

    def initialize(http_code)
      @http_code = http_code
      @auth_count = 0
    end
    def authenticate
      @auth_count += 1
      if @auth_count < 5
        puts "got auth, return with http code #{@http_code}"
        @http_code
      else
        puts "got auth, return 200"
        200
      end
    end

    def get_auth_count
      @auth_count
    end
  end

  class AuthSuccessCallback < ClientCallback

    def initialize
      @auth_success_latch = Concurrent::CountDownLatch.new(1)
    end

    def on_auth_success
      @auth_success_latch.count_down
    end

    def on_auth_failed
      raise "on_auth_failed should not be called"
    end

    def wait_for_auth_or_timeout
      @auth_success_latch.wait 30
    end
  end

  class AuthFailedCallback < ClientCallback

    def initialize
      @auth_failed_latch = Concurrent::CountDownLatch.new(1)
    end

    def on_auth_failed
      @auth_failed_latch.count_down
    end

    def wait_for_auth_failure_or_timeout
      @auth_failed_latch.wait 30000
    end
  end

  # auth has outright failed and will not be reattempted
  [401,403,404].each do |http_code|
    define_method("test_should_not_retry_on_#{http_code}") do
      callback = AuthFailedCallback.new
      service = AuthService.new ReturnHttpCodeConnector.new(http_code), callback, Logger.new(STDOUT)
      service.start_async
      assert callback.wait_for_auth_failure_or_timeout, "timed out waiting for authentication to fail"
      assert !(service.send :is_authenticated)
    end
  end

  # auth has failed but will succeed in the future
  [408,425,429,500,502,503,504].each do |http_code|
    define_method("test_should_retry_on_#{http_code}") do
      callback = AuthSuccessCallback.new
      connector = FailThenRecoverConnector.new(http_code)
      service = AuthService.new connector, callback, Logger.new(STDOUT), retry_delay_ms = 10
      service.start_async
      assert callback.wait_for_auth_or_timeout, "timed out waiting for authentication to succeed"
      assert service.send :is_authenticated
      assert_equal 5, connector.get_auth_count
    end
  end

end




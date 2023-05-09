require "minitest/autorun"
require "ff/ruby/server/sdk/common/sdk_codes"
require 'ff/ruby/server/sdk/dto/target'

class SdkCodeTest < Minitest::Test
  def test_logs_dont_raise_exception
    logger = Logger.new $stdout
    logger.level = Logger::DEBUG
    target = Target.new("RubySDK", identifier="rubysdk", attributes={"location": "emea"})

    SdkCodes.info_poll_started logger, 10
    SdkCodes.info_sdk_init_ok logger
    SdkCodes.info_sdk_auth_ok logger
    SdkCodes.info_polling_stopped logger
    SdkCodes.info_stream_connected logger
    SdkCodes.info_stream_event_received logger, ""
    SdkCodes.info_metrics_thread_started logger
    SdkCodes.warn_auth_failed_srv_defaults logger
    SdkCodes.warn_auth_retying logger, 1
    SdkCodes.warn_stream_disconnected logger, "example reason"
    SdkCodes.warn_post_metrics_failed logger, "example reason"
    SdkCodes.warn_default_variation_served logger, "identifier", target, "default"
  end
end
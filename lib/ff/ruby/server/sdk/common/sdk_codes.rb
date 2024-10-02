
class SdkCodes
  def self.raise_missing_sdk_key(logger)
    msg = SdkCodes.sdk_err_msg(1002)
    logger.error msg
    raise msg
  end

  def self.info_poll_started(logger, durationSec)
    logger.info SdkCodes.sdk_err_msg(4000, durationSec*1000)
  end

  def self.info_sdk_init_ok(logger)
    logger.info SdkCodes.sdk_err_msg(1000)
  end

  def self.info_sdk_waiting_to_initialize(logger, timeout)
    if timeout
      message = "with timeout: #{timeout} ms"
    else

      message = "with no timeout"

    end
    logger.info SdkCodes.sdk_err_msg(1003, message)
  end

  def self.info_sdk_auth_ok(logger)
    logger.info SdkCodes.sdk_err_msg(2000)
  end

  def self.info_polling_stopped(logger)
    logger.info SdkCodes.sdk_err_msg(4001)
  end

  def self.info_stream_connected(logger)
    logger.info SdkCodes.sdk_err_msg(5000)
  end

  def self.info_stream_event_received(logger, event_json)
    logger.info SdkCodes.sdk_err_msg(5002, event_json)
  end

  def self.info_metrics_thread_started(logger)
    logger.info SdkCodes.sdk_err_msg(7000)
  end

  def self.warn_metrics_targets_max_size_exceeded(logger)
    logger.warn SdkCodes.sdk_err_msg(7004)
  end

  def self.warn_metrics_evaluations_max_size_exceeded(logger)
    logger.warn SdkCodes.sdk_err_msg(7007)
  end
  def self.warn_auth_failed_srv_defaults(logger)
    logger.warn SdkCodes.sdk_err_msg(2001)
  end

  def self.warn_auth_retying(logger, attempt)
    logger.warn SdkCodes.sdk_err_msg(2003, ", attempt #{attempt}")
  end

  def self.warn_stream_disconnected(logger, reason)
    logger.warn SdkCodes.sdk_err_msg(5001, reason)
  end

  def self.warn_post_metrics_failed(logger, reason)
    logger.warn SdkCodes.sdk_err_msg(7002, reason)
  end

  def self.warn_default_variation_served(logger, identifier, target, default)
    logger.warn SdkCodes.sdk_err_msg(6001, "identifier=%s, target=%s, default=%s" % [identifier, target.identifier, default])
  end

  def self.warn_bucket_by_attr_not_found(logger, attr_name, new_value)
    if new_value == nil
      new_value = "NOT FOUND"
    end
    logger.warn SdkCodes.sdk_err_msg(6002, "missing=%s, using value=%s" % [attr_name, new_value])
  end

  private

  @map =
    {
      # SDK_INIT_1xxx
      1000 => "The SDK has successfully initialized",
      1001 => "The SDK has failed to initialize due to the following authentication error:",
      1002 => "The SDK has failed to initialize due to a missing or empty API key",
      1003 => "The SDK is waiting for initialzation to complete",
      # SDK_AUTH_2xxx
      2000 => "Authenticated ok",
      2001 => "Authentication failed with a non-recoverable error - defaults will be served",
      2003 => "Retrying to authenticate",
      # SDK_POLL_4xxx
      4000 => "Polling started, intervalMs:",
      4001 => "Polling stopped",
      # SDK_STREAM_5xxx
      5000 => "SSE stream connected ok",
      5001 => "SSE stream disconnected, reason:",
      5002 => "SSE event received: ",
      5003 => "SSE retrying to connect in",
      # SDK_EVAL_6xxx
      6000 => "Evaluated variation successfully",
      6001 => "Default variation was served",
      6002 => "BucketBy attribute not found in target attributes, falling back to 'identifier':",
      # SDK_METRICS_7xxx
      7000 => "Metrics thread started",
      7001 => "Metrics thread exited",
      7002 => "Posting metrics failed, reason:",
      7004 => "Target metrics exceeded max size, remaining targets for this analytics interval will not be sent",
      7007 => "Evaluation metrics exceeded max size, remaining evaluations for this analytics interval will not be sent"
    }

  def self.sdk_err_msg(error_code, append_text = "")
    "SDKCODE(%s:%s): %s %s" % [(get_err_class error_code), error_code, @map[error_code], append_text]
  end

  def self.get_err_class(error_code)
    if error_code >= 1000 and error_code <= 1999
      return "init"
    elsif error_code >= 2000 and error_code <= 2999 then return "auth"
    elsif error_code >= 4000 and error_code <= 4999 then return "poll"
    elsif error_code >= 5000 and error_code <= 5999 then return "stream"
    elsif error_code >= 6000 and error_code <= 6999 then return "eval"
    elsif error_code >= 7000 and error_code <= 7999 then return "metric"
    end
    ""
  end

end
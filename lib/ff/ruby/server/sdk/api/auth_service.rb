require_relative "../common/closeable"

class AuthService < Closeable

  def initialize(connector, callback, logger, retry_delay_ms = 6000)

    unless connector.kind_of?(Connector)
      raise "The 'connector' parameter must be of '" + Connector.to_s + "' data type"
    end

    unless callback.kind_of?(ClientCallback)
      raise "The 'callback' parameter must be of '" + ClientCallback.to_s + "' data type"
    end

    @logger = logger
    @callback = callback
    @connector = connector
    @retry_delay_ms = retry_delay_ms
    @authenticated = false
  end

  def start_async
    @logger.debug "Async starting: " + self.to_s

    @thread = Thread.new :report_on_exception => true do
      attempt = 1
      until @authenticated do
        http_code = @connector.authenticate

        if http_code == 200
          @authenticated = true
          @callback.on_auth_success
          stop_async
        elsif should_retry_http_code http_code
          delay_ms = @retry_delay_ms * [10, attempt].min
          @logger.warn "Got HTTP code #{http_code} while authenticating on attempt #{attempt}, will retry in #{delay_ms} ms"
          sleep(delay_ms/1000)
          attempt += 1
          SdkCodes::warn_auth_retying @logger, attempt
        else
          @logger.warn "Auth Service got HTTP code #{http_code} while authenticating, will not attempt to reconnect"
          @callback.on_auth_failed
          stop_async
          next
        end
      end
    end

    @thread.run
  end

  def close
    stop_async
  end

  protected

  def on_auth_success

    if @callback != nil
      unless @callback.kind_of?(ClientCallback)
        raise "Expected '" + ClientCallback.to_s + "' data type for the callback"
      end
      @callback.on_auth_success
    end
  end

  def stop_async
    if @thread != nil
      @logger.debug "Stopping Auth service, status=#{@thread.status}"
      @thread.exit
      @thread = nil
      @logger.debug "Stopping Auth service done"
    end
  end

  private

  def is_authenticated
    @authenticated
  end

  def should_retry_http_code(code)
    # 408 request timeout
    # 425 too early
    # 429 too many requests
    # 500 internal server error
    # 502 bad gateway
    # 503 service unavailable
    # 504 gateway timeout
    #  -1 OpenAPI error (timeout etc)
    case code
    when 408,425,429,500,502,503,504,-1
      return true
    else
      return false
    end
  end
end
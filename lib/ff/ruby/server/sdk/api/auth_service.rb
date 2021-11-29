class AuthService

  def initialize(connector = nil, poll_interval_in_sec = 60, callback = nil)

    @callback = callback
  end

  def start_async

  end

  def on_auth_success

    unless @callback == nil

      unless @callback.kind_of?(AuthCallback)

        raise "Expected '" + AuthCallback.to_s + "' data type for the callback"
      end

      @callback.on_auth_success
    end
  end
end
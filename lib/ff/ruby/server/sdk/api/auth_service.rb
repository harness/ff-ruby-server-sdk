class AuthService

  def initialize(connector = nil, poll_interval_in_sec = 60, callback = nil)

    @callback = callback
  end

  def start_async

  end

  def on_auth_success

    unless @callback == nil

      @callback.on_auth_success
    end
  end
end
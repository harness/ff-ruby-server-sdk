require "rufus-scheduler"

class AuthService

  def initialize(connector = nil, poll_interval_in_sec = 60, callback = nil)

    @callback = callback
    @connector = connector
    @poll_interval_in_sec = poll_interval_in_sec
  end

  def start_async

    puts "Starting async: " + self .to_s

    @scheduler = Rufus::Scheduler.new

    @job = @scheduler.in "" do


    end
  end

  def close

    stop_async
  end

  def on_auth_success

    unless @callback == nil

      unless @callback.kind_of?(AuthCallback)

        raise "Expected '" + AuthCallback.to_s + "' data type for the callback"
      end

      @callback.on_auth_success
    end
  end

  protected

  def stop_async

    if @job != nil

      @job.kill
    end
  end

end
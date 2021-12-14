class PollerTestCallback

  attr_accessor :on_poller_ready_count, :on_poller_error_count, :on_poller_iteration_count

  def initialize
    super

    @on_poller_ready_count = 0
    @on_poller_error_count = 0
    @on_poller_iteration_count = 0
  end

  def on_poller_ready(poller)

    if poller == nil

      raise "Poller is nil"
    end

    @on_poller_ready_count = @on_poller_ready_count + 1
  end

  def on_poller_error(e)

    @on_poller_error_count = @on_poller_error_count + 1
  end

  def on_poller_iteration(poller)

    @on_poller_iteration_count = @on_poller_iteration_count + 1
  end
end
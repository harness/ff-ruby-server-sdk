require_relative "../common/closeable"

class ClientCallback < Closeable

  def initialize
    super

    @tbi = "To be implemented"
  end

  def on_auth_success

    raise @tbi
  end

  def on_authorized

    raise @tbi
  end

  def is_closing

    raise @tbi
  end

  def on_processor_ready(processor)

    raise @tbi
  end

  def on_update_processor_ready

    raise @tbi
  end

  def on_metrics_processor_ready

    raise @tbi
  end

  def update(message, manual)

    raise @tbi
  end
end
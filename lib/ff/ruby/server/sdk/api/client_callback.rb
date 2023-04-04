require_relative "../common/closeable"

class ClientCallback < Closeable

  TBI = RuntimeError.new("To be implemented")

  def initialize
    super
  end

  def on_auth_success

    raise TBI
  end

  def on_auth_failed

    raise TBI
  end

  def on_authorized

    raise TBI
  end

  def is_closing

    raise TBI
  end

  def on_processor_ready(processor)

    raise TBI
  end

  def on_update_processor_ready

    raise TBI
  end

  def on_metrics_processor_ready

    raise TBI
  end

  def update(message, manual)

    raise TBI
  end
end
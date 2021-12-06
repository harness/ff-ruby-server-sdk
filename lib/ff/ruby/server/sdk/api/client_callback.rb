require_relative "../common/closeable"

class ClientCallback < Closeable

  def on_auth_success

    raise "Not implemented"
  end

  def on_authorized

    raise "To be implemented"
  end
end
require_relative "connector"

class HarnessConnector < Connector

  def authenticate

    raise @tbe
  end

  def get_flags

    raise @tbe
  end

  def get_flag(identifier)

    raise @tbe
  end

  def get_segments

    raise @tbe
  end

  def get_segment(identifier)

    raise @tbe
  end

  def post_metrics(metrics)

    raise @tbe
  end

  def stream(updater)

    raise @tbe
  end
end
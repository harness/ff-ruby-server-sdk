require_relative "connector"

class HarnessConnector < Connector

  def initialize(

    sdk_key,
    options = nil,
    on_authorized
  )

    @sdk_key = sdk_key
    @options = options
    @on_authorized = on_authorized

    # TODO: Init API
  end

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
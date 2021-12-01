require_relative "connector"

class HarnessConnector < Connector

  def initialize(sdk_key, config = nil, on_authorized)

    @sdk_key = sdk_key
    @options = config
    @on_authorized = on_authorized

    @api = OpenapiClient::ClientApi.new
    @metrics_api = OpenapiClient::MetricsApi.new

    puts "Api: " + @api.to_s
    puts "Metrics api: " + @metrics_api.to_s
  end

  def authenticate



    false
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
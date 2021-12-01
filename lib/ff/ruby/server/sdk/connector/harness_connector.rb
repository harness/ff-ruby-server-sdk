require_relative "connector"

class HarnessConnector < Connector

  def initialize(sdk_key, config = nil, on_authorized)

    @sdk_key = sdk_key
    @options = config
    @on_authorized = on_authorized

    @api = make_api_client
    @metrics_api = make_metrics_api_client

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

  protected

  def make_api_client

    api_client = OpenapiClient::ApiClient.new

    config = ConfigBuilder.new.build
    api_client.config = config

    api_client
  end

  def make_metrics_api_client

    api_client = OpenapiClient::ApiClient.new

    config = ConfigBuilder.new.build
    api_client.config = config

    api_client
  end
end
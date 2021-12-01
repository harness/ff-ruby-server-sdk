require_relative "connector"
require_relative "../version"

class HarnessConnector < Connector

  def initialize(api_key, config, on_unauthorized)

    @api_key = api_key
    @options = config
    @on_unauthorized = on_unauthorized
    @user_agent = "RubySDK " + Ff::Ruby::Server::Sdk::VERSION

    @api = OpenapiClient::ClientApi.new(make_api_client)
    @metrics_api = OpenapiClient::MetricsApi.new(make_metrics_api_client)

    puts "Api: " + @api.to_s
    puts "Metrics api: " + @metrics_api.to_s
  end

  def authenticate

    request = OpenapiClient::AuthenticationRequest.new
    request.api_key = @api_key

    begin

      response = @api.authenticate
      @token = response.auth_token

    rescue OpenapiClient::ApiError => e

      puts "ERROR - Start\n\n" + e.to_s + "\nERROR - End"
    end

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

    api_client.config = @options
    api_client.user_agent = @user_agent

    api_client

    # TODO: Interceptor

    api_client
  end

  def make_metrics_api_client

    max_timeout = 30 * 60 * 1000

    api_client = OpenapiClient::ApiClient.new

    config = @options.clone

    # TODO: Check base path

    config.connection_timeout = max_timeout
    config.read_timeout = max_timeout
    config.write_timeout = max_timeout

    api_client.config = config
    api_client.user_agent = @user_agent

    # TODO: Interceptor

    api_client
  end
end
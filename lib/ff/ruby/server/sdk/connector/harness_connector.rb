require "jwt"

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

    begin

      options = {
        :'authentication_request' => {
          :'apiKey' => @api_key
        }
      }

      response = @api.authenticate(opts = options)
      @token = response.auth_token

      puts "Token has been obtained: " + @token
      process_token
      return true

    rescue OpenapiClient::ApiError => e

      puts "ERROR - Start\n\n" + e.to_s + "\nERROR - End"
    end

    false
  end

  def get_flags

    puts "To be implemented: get_flags"
    []
  end

  def get_segments

    puts "To be implemented: get_segments"
    []
  end

  def get_flag(identifier)

    raise @tbi
  end

  def get_segment(identifier)

    raise @tbi
  end

  def post_metrics(metrics)

    raise @tbi
  end

  def stream(updater)

    raise @tbi
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

  def process_token

    headers = {

      "Authorization" => "Bearer " + @token
    }

    @api.api_client.default_headers.merge(headers)
    @metrics_api.api_client.default_headers.merge(headers)

    decoded_token = JWT.decode @token, nil, false

    if decoded_token != nil && !decoded_token.empty?

      @environment = decoded_token[0]["environment"]
      @cluster = decoded_token[0]["clusterIdentifier"]

      puts "Token has been processed: environment='" + @environment.to_s + "', cluster='" + @cluster.to_s + "'"
    else

      puts "ERROR: Could not obtain the environment and cluster data from the token"
    end
  end
end
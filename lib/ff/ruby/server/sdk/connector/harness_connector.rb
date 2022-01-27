require "jwt"

require_relative "events"
require_relative "connector"

require_relative "../version"

class HarnessConnector < Connector

  def initialize(api_key, config, on_unauthorized)

    @api_key = api_key
    @config = config
    @on_unauthorized = on_unauthorized
    @user_agent = "RubySDK " + Ff::Ruby::Server::Sdk::VERSION

    @api = OpenapiClient::ClientApi.new(make_api_client)
    @metrics_api = OpenapiClient::MetricsApi.new(make_metrics_api_client)

    @config.logger.debug "Api: " + @api.to_s
    @config.logger.debug "Metrics api: " + @metrics_api.to_s
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

      @config.logger.info "Token has been obtained: " + @token
      process_token
      return true

    rescue OpenapiClient::ApiError => e

      log_error(e)
    end

    false
  end

  def get_flags

    begin

      return @api.get_feature_config(

        environment_uuid = @environment,
        opts = get_query_params
      )

    rescue OpenapiClient::ApiError => e

      log_error(e)
    end
  end

  def get_segments

    begin

      return @api.get_all_segments(

        environment_uuid = @environment,
        opts = get_query_params
      )

    rescue OpenapiClient::ApiError => e

      log_error(e)
    end
  end

  def get_flag(identifier)

    @api.get_feature_config_by_identifier(

      identifier = identifier,
      environment_uuid = @environment,
      opts = get_query_params
    )
  end

  def get_segment(identifier)

    @api.get_segment_by_identifier(

      identifier = identifier,
      environment_uuid = @environment,
      opts = get_query_params
    )
  end

  def post_metrics(metrics)

    begin

      options = {

        :'metrics' => metrics,
        :'query_params' => {

          :'cluster' => @cluster
        }
      }

      @metrics_api.post_metrics(

        environment = @environment,
        opts = options
      )

      @config.logger.info "Successfully sent analytics data to the server"

    rescue OpenapiClient::ApiError => e

      log_error(e)
      @config.logger.error "Exception while posting metrics to the event server"
    end
  end

  def stream(updater)

    if @event_source != nil

      @event_source.close
      @event_source = nil
    end

    url = @config.config_url + "/stream?cluster=" + @cluster.to_s

    headers = {

      "Authorization" => "Bearer " + @token,
      "API-Key" => @api_key
    }

    @event_source = Events.new(

      url,
      headers,
      updater
    )

    @event_source
  end

  def close

    if @event_source != nil

      @event_source.close
      @event_source = nil
    end
  end

  protected

  def make_api_client

    api_client = OpenapiClient::ApiClient.new

    api_client.config = @config
    api_client.user_agent = @user_agent

    api_client
  end

  def make_metrics_api_client

    max_timeout = 30 * 60 * 1000

    api_client = OpenapiClient::ApiClient.new

    config = @config.clone

    config.read_timeout = max_timeout
    config.write_timeout = max_timeout
    config.connection_timeout = max_timeout
    config.base_url = config.event_url

    api_client.config = config
    api_client.user_agent = @user_agent

    api_client
  end

  def process_token

    headers = {

      "Authorization" => "Bearer " + @token
    }

    @api.api_client.default_headers = @api.api_client.default_headers.merge(headers)
    @metrics_api.api_client.default_headers = @metrics_api.api_client.default_headers.merge(headers)

    decoded_token = JWT.decode @token, nil, false

    if decoded_token != nil && !decoded_token.empty?

      @environment = decoded_token[0]["environment"]
      @cluster = decoded_token[0]["clusterIdentifier"]

      @config.logger.debug "Token has been processed: environment='" + @environment.to_s + "', cluster='" + @cluster.to_s + "'"
    else

      @config.logger.error "ERROR: Could not obtain the environment and cluster data from the token"
    end
  end

  private

  def get_query_params

    {
      :'query_params' => {

        :'cluster' => @cluster
      }
    }
  end

  def log_error(e)

    @config.logger.error "ERROR - Start\n\n" + e.to_s + "\nERROR - End"
  end
end
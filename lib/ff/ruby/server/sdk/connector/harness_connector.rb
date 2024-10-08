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
    @sdk_info = "Ruby #{Ff::Ruby::Server::Sdk::VERSION} Server"

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

      @config.logger.debug "Token has been obtained"
      process_token
      return 200

    rescue OpenapiClient::ApiError => e

      if e.message.include? "the server returns an error"
        # NOTE openapi-generator 5.2.1 has a bug where exceptions don't contain any useful information and we can't
        # determine if a timeout has occurred. This is fixed in 6.3.0 but requires Ruby version to be increased to 2.7
        # https://github.com/OpenAPITools/openapi-generator/releases/tag/v6.3.0
        @config.logger.warn "OpenapiClient::ApiError [\n\n#{e}\n]"

        if e.code
          return e.code
        end

        return -1
      end

      log_error("auth", e)
      return e.code
    end
  end

  def get_flags

    begin

      return @api.get_feature_config(

        environment_uuid = @environment,
        opts = get_query_params
      )

    rescue OpenapiClient::ApiError => e

      log_error("get_feature_config", e)
      return nil
    end
  end

  def get_segments

    begin
      return @api.get_all_segments(

        environment_uuid = @environment,
        opts = get_segment_query_params
      )

    rescue OpenapiClient::ApiError => e

      log_error("get_all_segments", e)
      return nil
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
      opts = get_segment_query_params
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

      @config.logger.debug "Successfully sent analytics data to the server"

    rescue OpenapiClient::ApiError => e
      log_error("post_metrics", e)
      SdkCodes.warn_post_metrics_failed @config.logger, e.message
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
      "API-Key" => @api_key,
      "User-Agent" => @user_agent,
      "Harness-SDK-Info" =>  @sdk_info,
      "Harness-AccountID" => @account_id,
      "Harness-EnvironmentID" => @environment_id
    }.compact

    @event_source = Events.new(

      url,
      headers,
      updater,
      @config
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
    api_client.config.connection_timeout = @config.read_timeout / 1000
    api_client.config.read_timeout = @config.read_timeout / 1000
    api_client.user_agent = @user_agent
    api_client.default_headers['Harness-SDK-Info'] = @sdk_info

    api_client
  end

  def make_metrics_api_client

    max_timeout = 30 * 60 * 1000

    api_client = OpenapiClient::ApiClient.new

    config = @config.clone

    config.read_timeout = max_timeout
    config.write_timeout = max_timeout
    config.connection_timeout = max_timeout
    config.config_url = config.event_url

    api_client.config = config
    api_client.user_agent = @user_agent
    api_client.default_headers['Harness-SDK-Info'] = @sdk_info

    api_client
  end

  def process_token
    decoded_token = JWT.decode @token, nil, false

    if decoded_token != nil && !decoded_token.empty?

      @environment = decoded_token[0]["environment"]
      @cluster = decoded_token[0]["clusterIdentifier"]
      @environment_id = decoded_token[0]["environmentIdentifier"]
      @account_id = decoded_token[0]["accountID"]

      headers = {
        "Authorization" => "Bearer " + @token,
        "Harness-AccountID" => @account_id,
        "Harness-EnvironmentID" => @environment_id
      }.compact

      @api.api_client.default_headers = @api.api_client.default_headers.merge(headers)
      @metrics_api.api_client.default_headers = @metrics_api.api_client.default_headers.merge(headers)

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

  def get_segment_query_params
    {
      :'query_params' => {

        :'cluster' => @cluster,
        :'rules' => 'v2'
      }
    }
  end

  def log_error(prefix, e)

    if e.code == 0
      type = "typhoeus/libcurl"
    else
      type = "HTTP code #{e.code}"
    end

    @config.logger.warn "%s: OpenapiClient::ApiError (%s) [\n\n%s\n]" % [prefix, type, e.to_s]
  end
end
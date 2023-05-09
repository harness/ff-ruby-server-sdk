require "json"
require 'restclient'

require_relative './service'
require_relative "../common/sdk_codes"
class Events < Service

  def initialize(

    url,
    headers,
    updater,
    config
  )

    @url = url
    @headers = headers
    @headers['params'] = {}
    @updater = updater
    @config = config

    if @updater != nil
      unless @updater.kind_of?(Updater)
        raise "The 'callback' parameter must be of '" + Updater.to_s + "' data type"
      end
    end

    if @config.logger != nil
      @logger = @config.logger
    else
      @logger = Logger.new(STDOUT)
    end

    @updater.on_ready
  end

  def start
    @logger.debug "Starting EventSource service"
    begin
      conn = RestClient::Request.execute(method: :get,
                                         url: @url,
                                         headers: @headers,
                                         block_response: proc { |response| response_handler response },
                                         before_execution_proc: nil,
                                         log: false,
                                         read_timeout: 60,
                                         ssl_ca_file: @config.ssl_ca_cert)

    rescue => e
      on_error e.message
    end
  end

  def stop
    @logger.debug "Stopping EventSource service"
    on_closed
  end

  def close
    stop
  end

  def on_open
    SdkCodes::info_stream_connected @logger
    @updater.on_connected
  end

  def on_error(reason="")
    SdkCodes::warn_stream_disconnected @logger, reason
    @updater.on_error
    stop
  end

  def on_closed
    SdkCodes::warn_stream_disconnected @logger, "on_closed called"
    @updater.on_disconnected
  end

  def on_message(message)
    SdkCodes::info_stream_event_received @logger, message.to_s

    msg = JSON.parse(message)
    @updater.update(msg)
  end

  private

  def emit_line(line)
    if line.start_with?("data:")
      @logger.debug "SSE emit line: " + line
      on_message line[line.index("{")..-1]
    end
  end

  def response_handler(response)
    on_open
    case response.code
    when "200"
      line = ""
      response.read_body do |chunk|
        line << chunk
        while line.sub!(/^(.*)\n/,"")
            emit_line $1
        end
      end
      close
    else
      msg = "SSE ERROR: http_code=%d body=%d" % [response.code, response.body]
      @logger.warn msg
      on_error msg
    end
  end

end
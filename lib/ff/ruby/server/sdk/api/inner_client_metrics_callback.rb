require_relative "client_callback"
require_relative "metrics_callback"

class InnerClientMetricsCallback < MetricsCallback

  def initialize(client_callback, logger = nil)

    unless client_callback.kind_of?(ClientCallback)

      raise "The 'client_callback' parameter must be of '" + ClientCallback.to_s + "' data type"
    end

    if logger != nil

      @logger = logger
    else

      @logger = Logger.new(STDOUT)
    end

    @client_callback = client_callback
  end

  def on_metrics_ready

    @client_callback.on_metrics_processor_ready
  end

  def on_metrics_error(error)

    @logger.error "Metrics error: " + error.to_s
  end
end
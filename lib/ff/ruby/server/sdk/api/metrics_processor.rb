require_relative "../common/closeable"

class MetricsProcessor < Closeable

  def initialize(

    connector,
    config,
    callback
  )

    @config = config
    @callback = callback
    @connector = connector
  end

  def push_to_queue(

    target,
    feature_config,
    variation
  )


  end

  def send_data_and_reset_cache(data)


  end

  def start

  end

  def stop

  end

  def close

  end

  protected

  def prepare_summary_metrics_body(data)

  end

  def run_one_iteration

  end

  private

  def prepare_summary_metrics_key(key)

  end

  def add_target(metrics, target)

  end

  def get_version

    nil
  end
end
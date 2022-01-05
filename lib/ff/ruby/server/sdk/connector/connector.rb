require_relative '../common/closeable'

class Connector < Closeable

  def initialize

    @tbi = "To be implemented"
  end

  def authenticate

    raise @tbi
  end

  def get_flags

    raise @tbi
  end

  def get_flag(identifier)

    raise @tbi
  end

  def get_segments

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
end
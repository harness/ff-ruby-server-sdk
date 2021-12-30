require_relative "../common/closeable"

class Service < Closeable

  def initialize

    @tbi = "To be implemented"
  end

  def start

    raise @tbi
  end

  def stop

    raise @tbi
  end
end
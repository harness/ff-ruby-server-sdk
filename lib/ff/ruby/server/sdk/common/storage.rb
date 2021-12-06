require_relative "closeable"

class Storage < Closeable

  def initialize

    @tbi = "To be implemented"
  end

  def set(key, value)

    raise @tbi
  end

  def get(key)

    raise @tbi
  end

  def delete(key)

    raise @tbi
  end

  def keys

    raise @tbi
  end
end
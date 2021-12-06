require_relative "closeable"

class Storage < Closeable

  def initialize

    @tbe = "To be implemented"
  end

  def set(key, value)

    raise @tbe
  end

  def get(key)

    raise @tbe
  end

  def delete(key)

    raise @tbe
  end

  def keys

    raise @tbe
  end
end
require_relative "../common/storage"

class FileMapStore < Storage

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

  def close

    super
  end
end
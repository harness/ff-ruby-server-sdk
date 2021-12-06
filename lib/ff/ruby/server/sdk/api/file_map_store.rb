require "moneta"
require_relative "../common/storage"

class FileMapStore < Storage

  def initialize

    @store = Moneta.new(:File, dir: "moneta")
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

    if @store != nil

      @store.close
    end
  end
end
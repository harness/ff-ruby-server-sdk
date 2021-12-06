require "moneta"
require_relative "../common/storage"

class FileMapStore < Storage

  def initialize

    @store = Moneta.new(:File, dir: "moneta")
  end

  def set(key, value)

    check_init

    @store[key] = value
  end

  def get(key)

    check_init

    @store[key]
  end

  def delete(key)

    check_init

    @store.delete(key)
  end

  def keys

    check_init

    raise @store.keys
  end

  def close

    if @store != nil

      @store.close
    end
  end

  private

  def check_init

    if @store == nil

      raise "Not initialized"
    end
  end
end
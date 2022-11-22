require "set"
require "fileutils"
require "libcache"

class DefaultCache < Cache

  attr_accessor :logger

  def initialize(logger = nil)

    if logger != nil

      @logger = logger
    else

      @logger = Logger.new(STDOUT)
    end

    @keys = Set[]
    @capacity = 10 * 1000

    lambda = lambda { |*key| @logger.debug "Retrieved #{key}" }

    @in_memory = CacheBuilder.with(Cache)
                             .set_max(@capacity)
                             .set_post_get(lambda)
                             .build
  end

  def verify
    @in_memory != nil && @capacity > 0
  end

  def set(key, value)

    begin
      @in_memory.put(key, value)

    rescue ArgumentError => e

      @logger.error "ERROR: " + e.to_s

      raise "Invalid arguments passed to the 'set' method: key='" + key.to_s + "', value='" + value.to_s + "'"
    end
  end

  def get(key)

    value = @in_memory.get(key)
    value
  end

  def delete(key)

    if key == nil

      raise "Key is nil"
    end

    if @in_memory.exists?(key)

      @in_memory.invalidate(key)
    end

    @keys.delete(key)
  end

  def keys

    @keys
  end

  private

  def directory_exists?(directory)

    File.directory?(directory)
  end
end
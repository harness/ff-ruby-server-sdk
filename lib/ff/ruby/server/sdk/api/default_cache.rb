require "set"
require "fileutils"
require "libcache"

class DefaultCache < Cache

  def initialize(logger = nil)

    if logger != nil

      @logger = logger
    else

      @logger = Logger.new(STDOUT)
    end

    @keys = Set[]
    @capacity = 10 * 1000

    lambda = lambda { |*key| @logger.debug "Retrieved #{key}" }

    cache_dir = "./cache"
    unless directory_exists?(cache_dir)

      FileUtils.mkdir_p cache_dir
      unless directory_exists?(cache_dir)

        raise "Failed to initialize filesystem cache at: " + cache_dir
      end
    end

    @filesystem = CacheBuilder.with(FileCache)
                              .set_store(cache_dir)
                              .set_max(@capacity)
                              .set_post_get(lambda)
                              .build

    @in_memory = CacheBuilder.with(Cache)
                             .set_max(@capacity)
                             .set_post_get(lambda)
                             .build
  end

  def verify

    @in_memory != nil && @filesystem != nil && @capacity > 0
  end

  def set(key, value)

    begin
      @in_memory.put(key, value)
      @filesystem.put(key, value)
      keys.add(key)

    rescue ArgumentError => e

      @logger.error "ERROR: " + e.to_s

      raise "Invalid arguments passed to the 'set' method: key='" + key.to_s + "', value='" + value.to_s + "'"
    end
  end

  def get(key)

    value = @in_memory.get(key)

    if value == nil

      value = @filesystem.get(key)
      if value != nil

        @in_memory.put(key, value)
      end
    end
    value
  end

  def delete(key)

    if key == nil

      raise "Key is nil"
    end

    if @in_memory.exists?(key)

      @in_memory.invalidate(key)
    end

    if @filesystem.exists?(key)

      @filesystem.invalidate(key)
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
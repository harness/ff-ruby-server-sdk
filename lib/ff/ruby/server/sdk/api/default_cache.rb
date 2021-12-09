require "set"
require "fileutils"
require "libcache"

class DefaultCache < Cache

  def initialize
    super

    @keys = Set[]
    @capacity = 10 * 1000

    lambda = lambda { |*key| puts "Retrieved #{key}" }

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

    @in_memory.put(key, value)
    @filesystem.put(key, value)
    keys.add(key)
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

    @in_memory.invalidate(key)
    @filesystem.invalidate(key)
    keys.delete(key)
  end

  def keys

    @keys
  end

  private

  def directory_exists?(directory)

    File.directory?(directory)
  end
end
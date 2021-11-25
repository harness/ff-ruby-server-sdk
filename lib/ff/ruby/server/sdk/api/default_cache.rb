require "set"
require "libcache"

class DefaultCache < Cache

  def initialize
    super

    @keys = Set[]
    @capacity = 10 * 1000

    lambda = lambda { |*key| puts "Retrieved #{key}" }

    @filesystem = CacheBuilder.with(FileCache)
                              .set_store("sdk/cache")
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

    keys.add(key)
    @in_memory.put(key, value)
    @filesystem.put(key, value)
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

    keys.delete(key)
    @in_memory.delete(key)
    @filesystem.delete(key)
  end

  def keys

    @keys
  end
end
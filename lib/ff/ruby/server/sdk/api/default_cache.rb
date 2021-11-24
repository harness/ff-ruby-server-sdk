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

    # TODO: Populate in-memory cache
  end

  def verify

    @in_memory != nil && @filesystem != nil && @capacity > 0
  end

  def set(key, value)

    keys.add(key)

    # TODO: Implement
  end

  def get(key)

    raise @tbe
  end

  def delete(key)

    keys.delete(key)

    # TODO: Implement
  end

  def keys

    @keys
  end
end
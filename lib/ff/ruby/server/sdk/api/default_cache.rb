require "libcache"

class DefaultCache < Cache

  def initialize
    super

    @capacity = 10 * 1000

    lambda = lambda { |*key| puts "Retrieved #{key}" }

    @in_memory = CacheBuilder.with(Cache)
                             .set_max(@capacity)
                             .set_post_get(lambda)
                             .build

    @filesystem = CacheBuilder.with(FileCache)
                              .set_store("sdk/cache")
                              .set_max(@capacity)
                              .set_post_get(lambda)
                              .build
  end

  def verify

    @in_memory != nil && @filesystem != nil && @capacity > 0
  end
end
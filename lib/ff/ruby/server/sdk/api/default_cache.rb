require "libcache"

class DefaultCache < Cache

  def initialize
    super

    @in_memory = CacheBuilder.with(Cache)
                             .set_expiry('3s')
                             .set_max(500)
                             .set_refresh(lambda { |key| key + 100 })
                             .set_post_get(lambda { |*key| puts "Retrieved #{key}!" })
                             .build

    @filesystem = CacheBuilder.with(FileCache)
                              .set_store("cache")
                              .set_expiry('3s')
                              .set_max(500)
                              .set_refresh(lambda { |key| key + 100 })
                              .set_post_get(lambda { |*key| puts "Retrieved #{key}!" })
                              .build
  end

  def verify

    @in_memory != nil && @filesystem != nil
  end
end
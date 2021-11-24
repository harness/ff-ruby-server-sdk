require_relative '../lib/ff/ruby/server/sdk/api/cf_client'
require_relative '../lib/ff/ruby/server/sdk/api/inner_client'
require_relative '../lib/ff/ruby/server/sdk/api/config'
require_relative '../lib/ff/ruby/server/sdk/api/config_builder'
require_relative '../lib/ff/ruby/server/sdk/api/default_cache'

bool = false
number = 100
string = "test"

cache = DefaultCache.new

config = ConfigBuilder.new
                      .event_url(string)
                      .config_url(string)
                      .stream_enabled(bool)
                      .poll_interval_in_seconds(number)
                      .analytics_enabled(bool)
                      .frequency(number)
                      .buffer_size(number)
                      .all_attributes_private(!bool)
                      .private_attributes(Set[string])
                      .connection_timeout(number)
                      .read_timeout(number)
                      .write_timeout(number)
                      .debug(!bool)
                      .metrics_service_acceptable_duration(number)
                      .cache(cache)
                      .build

puts config.describe

client = CfClient.instance
client2 = CfClient.new(string, config)
client3 = CfClient.instance

client.hello
client2.hello
client3.hello

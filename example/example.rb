require_relative '../lib/ff/ruby/server/sdk/api/cf_client'
require_relative '../lib/ff/ruby/server/sdk/dto/target'
require_relative '../lib/ff/ruby/server/sdk/api/config'
require_relative '../lib/ff/ruby/server/sdk/api/config_builder'

client = CfClient.instance

# Non-Freemium:
# key = "e22567cb-ccbd-4460-aa8a-751c24c7efda"
# Freemium:
# key = "b5701b02-76c0-45eb-a0fa-051b514f040d"

# UAT:
key = "8b00e7d0-3415-4c1e-a75b-f2b449e39ccc"

config = ConfigBuilder.new
                      .base_url("https://config.feature-flags.uat.harness.io/api/1.0")
                      .config_url("https://config.feature-flags.uat.harness.io/api/1.0/stream")
                      .event_url("https://event.feature-flags.uat.harness.io/api/1.0")
                      .build

client.init(

  api_key = key,
  config = config
)

client.wait_for_initialization

while true do

  bool_flag = "flag1"
  target = Target.new("ruby_target_1")

  bool_result = client.bool_variation(bool_flag, target, false)

  puts bool_flag + " has value of: " + bool_result

  sleep 10
end


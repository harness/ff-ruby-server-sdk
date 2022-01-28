require_relative '../lib/ff/ruby/server/sdk/api/cf_client'
require_relative '../lib/ff/ruby/server/sdk/dto/target'
require_relative '../lib/ff/ruby/server/sdk/api/config'
require_relative '../lib/ff/ruby/server/sdk/api/config_builder'

client = CfClient.instance

# Non-Freemium:
# key = "e22567cb-ccbd-4460-aa8a-751c24c7efda"

# Freemium:
# key = "76c48e81-674a-41a0-beee-838f44ee45b5"

# UAT:
key = "8b00e7d0-3415-4c1e-a75b-f2b449e39ccc"

config = ConfigBuilder.new
                      .config_url("https://config.feature-flags.uat.harness.io/api/1.0")
                      .event_url("https://event.feature-flags.uat.harness.io/api/1.0")
                      .build

client.init(

  api_key = key,
  config = config
)

config.logger.debug "We will wait for the initialization"

client.wait_for_initialization

config.logger.debug "Initialization is complete"

while true do

  bool_flag = "flag1"
  number_flag = "flag2"
  string_flag = "flag3"
  json_flag = "flag4"

  target = Target.new("ruby_target_1")

  bool_result = client.bool_variation(bool_flag, target, false)
  number_result = client.number_variation(number_flag, target, -1)
  string_result = client.string_variation(string_flag, target, "unavailable !!!")
  json_result = client.json_variation(json_flag, target, JSON.parse("{}"))

  config.logger.debug "'" + bool_flag.to_s + "' has the value of: " + bool_result.to_s
  config.logger.debug "'" + number_flag.to_s + "' has the value of: " + number_result.to_s
  config.logger.debug "'" + string_flag.to_s + "' has the value of: " + string_result.to_s
  config.logger.debug "'" + json_flag.to_s + "' has the value of: " + json_result.to_s

  sleep 10
end


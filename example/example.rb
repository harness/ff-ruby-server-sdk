require_relative '../lib/ff/ruby/server/sdk/api/cf_client'
require_relative '../lib/ff/ruby/server/sdk/api/config'
require_relative '../lib/ff/ruby/server/sdk/api/config_builder'

client = CfClient.instance

# Non-Freemium:
key = "e22567cb-ccbd-4460-aa8a-751c24c7efda"
# Freemium:
# key = "b5701b02-76c0-45eb-a0fa-051b514f040d"

config = ConfigBuilder.new.build

client.init(

  api_key = key,
  config = config
)

sleep


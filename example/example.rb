require_relative '../lib/ff/ruby/server/sdk/api/cf_client'
require_relative '../lib/ff/ruby/server/sdk/api/config'
require_relative '../lib/ff/ruby/server/sdk/api/config_builder'

client = CfClient.instance

key = "e22567cb-ccbd-4460-aa8a-751c24c7efda"

config = ConfigBuilder.new.build

client.init(

  api_key = key,
  config = config
)

sleep


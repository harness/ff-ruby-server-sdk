require_relative '../lib/ff/ruby/server/sdk/api/cf_client'
require_relative '../lib/ff/ruby/server/sdk/api/config'
require_relative '../lib/ff/ruby/server/sdk/api/config_builder'

client = CfClient.instance

key = "tbd"

config = ConfigBuilder.new.build

client.init(

  sdk_key = key,
  config = config
)


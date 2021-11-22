require_relative '../lib/ff/ruby/server/sdk/api/client'
require_relative '../lib/ff/ruby/server/sdk/api/cf_client'
require_relative '../lib/ff/ruby/server/sdk/api/inner_client'
require_relative '../lib/ff/ruby/server/sdk/api/config'

client = CfClient.instance
client2 = Client.new("aa", "bb")
client3 = CfClient.instance

client.hello
client2.hello
client3.hello
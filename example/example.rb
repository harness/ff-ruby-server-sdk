require_relative '../lib/ff/ruby/server/sdk'

client = CfClient.instance
client2 = CfClient.new
client3 = CfClient.instance

client.hello
client2.hello
client3.hello
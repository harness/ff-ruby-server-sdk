require 'ff/ruby/server/sdk/api/config'
require 'ff/ruby/server/sdk/dto/target'
require 'ff/ruby/server/sdk/api/cf_client'
require 'ff/ruby/server/sdk/api/config_builder'

require "logger"
require "securerandom"

$stdout.sync = true
logger = Logger.new $stdout

# API Key
key = "94d08df6-da94-4453-b9a1-95dd8698e98d"

# Flag Name
flagName = ENV['FF_FLAG_NAME'] || 'harnessappdemodarkmode'

# Create a Feature Flag Client and wait for it to initialize
client = CfClient.instance

client.init(key, ConfigBuilder.new.logger(logger).build)
client.wait_for_initialization

# Create a target (different targets can get different results based on rules.  This include a custom attribute 'location')
target = Target.new("RubySDK", identifier="rubysdk", attributes={"location": "emea"})

# Loop forever reporting the state of the flag
loop do
  result = client.bool_variation(flagName, target, false)
  logger.info "Flag variation:  #{result}"
  sleep 10
end

client.close



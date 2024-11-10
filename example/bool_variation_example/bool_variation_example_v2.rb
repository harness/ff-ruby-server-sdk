require 'ff/ruby/server/sdk/api/config'
require 'ff/ruby/server/sdk/dto/target'
require 'ff/ruby/server/sdk/api/cf_client'
require 'ff/ruby/server/sdk/api/config_builder'

require "logger"
require "securerandom"

$stdout.sync = true
logger = Logger.new $stdout

# API Key
apiKey = ENV['FF_API_KEY'] || 'changeme'

# Flag Name
flagName = ENV['FF_FLAG_NAME'] || 'identifier_of_your_bool_flag'

# Create a Feature Flag Client and wait for it to initialize
client = CfClient.instance

client.init(api_key: apiKey, config: ConfigBuilder.new.logger(logger).build)
client.wait_for_initialization

# Create a target (different targets can get different results based on rules.  This include a custom attribute 'location')
target = Target.new(identifier: "RubySDK", name: "rubysdk", attributes: {"location": "emea"})

# Loop forever reporting the state of the flag
loop do
  result = client.bool_variation(identifier: flagName, target: target, default_value: false)
  logger.info "Flag variation:  #{result}"
  sleep 10
end

client.close



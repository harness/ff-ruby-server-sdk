require 'ff/ruby/server/sdk/api/config'
require 'ff/ruby/server/sdk/dto/target'
require 'ff/ruby/server/sdk/api/cf_client'
require 'ff/ruby/server/sdk/api/config_builder'

require "logger"
require "securerandom"

$stdout.sync = true
logger = Logger.new $stdout
logger.level = Logger::DEBUG

# API Key
apiKey = ENV['FF_API_KEY'] || 'changeme'

# Flag Name
flagName = ENV['FF_FLAG_NAME'] || 'harnessappdemodarkmode'

logger.info "Harness Ruby SDK Getting Started"

# Create a Feature Flag Client and wait for it to initialize
client = CfClient.instance

client.init(apiKey, ConfigBuilder.new.logger(logger).build)

logger.info "----- initialization started ----- "
logger.info "initialised: #{client.initialized}"
client.wait_for_initialization
logger.info "----- initialization done ----- "
logger.info "initialised: #{client.initialized}"

# Create a target (different targets can get different results based on rules.  This include a custom attribute 'location')
target = Target.new("RubySDK", identifier="rubysdk", attributes={"location": "emea"})

# Loop forever reporting the state of the flag
loop do
  result = client.bool_variation(flagName, target, false)
  logger.info "Flag #{flagName} is set to:  #{result}"
  sleep 10
end

client.close



require "logger"
require "securerandom"

require_relative '../lib/ff/ruby/server/sdk/dto/target'
require_relative '../lib/ff/ruby/server/sdk/api/config'
require_relative '../lib/ff/ruby/server/sdk/api/cf_client'
require_relative '../lib/ff/ruby/server/sdk/api/config_builder'

flag_b = "flag1"
flag_n = "flag2"
flag_s = "flag3"
flag_j = "flag4"

clients = {}
targets = {}

logger = Logger.new(STDOUT)

executor = Concurrent::FixedThreadPool.new(100)

keys = {

  "Freemium" => "1f3339b4-e004-457a-91f7-9b5ce173eaaf",
  "Non-Freemium" => "a30cf6aa-67f2-4545-8ac7-f86709f4f3a0"
}

keys.each do |name, key|

  targets[name] = Target.new("ruby_target_" + name)

  config = ConfigBuilder.new
                        .logger(logger)
                        .build

  client = CfClient.new(key, config)

  # .config_url("https://config.feature-flags.uat.harness.io/api/1.0")
  # .event_url("https://event.feature-flags.uat.harness.io/api/1.0")

  client.init

  config.logger.debug "We will wait for the initialization"

  client.wait_for_initialization

  config.logger.debug "Initialization is complete"

  clients[name] = client
end

iterations = 10

counted = 0
count_to = keys.size * iterations

logger.debug "To count: " + count_to.to_s

keys.each do |name, key|

  client = clients[name]
  target = targets[name]

  executor.post do

    (1..iterations).each do |iteration|

      logger.debug name + " :: iteration no: " + iteration.to_s

      bool_result = client.bool_variation(flag_b, target, false)
      number_result = client.number_variation(flag_n, target, -1)
      string_result = client.string_variation(flag_s, target, "unavailable !!!")
      json_result = client.json_variation(flag_j, target, JSON.parse("{}"))

      logger.debug name + " :: '" + flag_b.to_s + "' has the value of: " + bool_result.to_s
      logger.debug name + " :: '" + flag_n.to_s + "' has the value of: " + number_result.to_s
      logger.debug name + " :: '" + flag_s.to_s + "' has the value of: " + string_result.to_s
      logger.debug name + " :: '" + flag_j.to_s + "' has the value of: " + json_result.to_s
      logger.debug "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"

      counted = counted + 1

      logger.debug "Counted: " + counted.to_s

      sleep 10
    end
  end
end

while counted != count_to

  sleep(1)
end

clients.each do |name, client|

  logger.debug name + " :: closing"

  client.close
end


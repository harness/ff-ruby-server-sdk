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
flagName = ENV['FF_FLAG_NAME'] || 'harnessappdemodarkmode'

logger.info "Harness Ruby SDK TLS example"

=begin
 For ff servers with a custom or private CAs, you can use 'tls_ca_cert' to pass in the CA bundle in ASCII PEM format.
 You should also include any intermediate CAs so the full trust chain can be resolved. Typhoeus HTTP client uses libcurl
 underneath, when developing you should enable debugging(true) to get more detailed error diagnostics logged, which
 aren't reported through OpenAPI. Common errors include:

 SSL peer certificate or SSH remote key was not OK - you have an invalid or missing CA for the server you're trying
                                                     to connect to. It can also mean the server hostname and request
                                                     hostname don't match.
 SSL: no alternative certificate subject name      - The hostname or IP used in your SDK URLs do not match the SANs
   matches target host name ‘<host>'                 configured in the cert sent by the web server. You should either
                                                     fix your URLs or ensure the SANs in the X.509 cert are configured
                                                     correctly.

The example below assumes you have an ff-server (or proxy) configured with TLS for a server hosted on
'ffserver:8000' where the web server's cert has a SANs with DNS entry 'ffserver'. CA.crt tells the SDK you trust this
server.

Typhoeus/libcurl by default has its default CA bundle stored at /etc/ssl/cert.pem. You can append your CA here if
you choose not to use 'tls_ca_cert'.

=end


client = CfClient.instance
client.init(api_key: apiKey, config: ConfigBuilder.new.logger(logger)
                                 .event_url("https://ffserver:8001/api/1.0")
                                 .config_url("https://ffserver:8000/api/1.0")
                                 .tls_ca_cert("/path/to/CA.crt")
                                 .debugging(true)
                                 .build)

client.wait_for_initialization


# Create a target (different targets can get different results based on rules.  This include a custom attribute 'location')
target = Target.new(identifier: "RubySDK", name: "rubysdk", attributes: {"location": "emea"})

# Loop forever reporting the state of the flag
loop do
  result = client.bool_variation(identifier: flagName, target: target, default_value: false)
  logger.info "#{flagName} flag variation:  #{result}"
  sleep 10
end

client.close



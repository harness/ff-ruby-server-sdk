Harness CF Ruby Server SDK
========================

## Table of Contents
**[Intro](#Intro)**<br>
**[Requirements](#Requirements)**<br>
**[Quickstart](#Quickstart)**<br>
**[Further Reading](docs/further_reading.md)**<br>
**[Build Instructions](docs/build.md)**<br>

## Intro

Harness Feature Flags (FF) is a feature management solution that enables users to change the software’s functionality, without deploying new code. FF uses feature flags to hide code or behaviours without having to ship new versions of the software. A feature flag is like a powerful if statement.
* For more information, see https://harness.io/products/feature-flags/
* To read more, see https://ngdocs.harness.io/category/vjolt35atg-feature-flags
* To sign up, https://app.harness.io/auth/#/signup/

![FeatureFlags](./docs/images/ff-gui.png)

## Requirements
Requirements
The Harness CF Ruby Server SDK has two versions, each supporting different Ruby versions:

SDK Version 1: Supports Ruby 2.7 up to, but not including, Ruby 3.0.
SDK Version 2: Required for Ruby 3.0 and newer.

## Version V2 Breaking Change Notice
- All public methods now enforce keyword arguments. 
- Singleton Pattern Enforcement: Multiple instances were not supported in V1, but the SDK could allow you to use multiple instance.
The SDK now follows the Singleton pattern, ensuring only a single instance of the SDK exists throughout the application's lifecycle. 
Any attempt to create additional SDK instances will reference the existing instance. This prevents unintended behaviors or conflicts that could arise from multiple SDK instances in a single application.

## Quickstart
The Feature Flag SDK provides a client that connects to the feature flag service, and fetches the value
of feature flags.   The following section provides an example of how to install the SDK and initialize it from
an application.
This quickstart assumes you have followed the instructions to [setup a Feature Flag project and have created a flag called `harnessappdemodarkmode` and created a server API Key](https://ngdocs.harness.io/article/1j7pdkqh7j-create-a-feature-flag#step_1_create_a_project).

### Install the SDK
Install the ruby SDK using gem
```bash
gem install ff-ruby-server-sdk
```
or by adding the following snippet to your project's `Gemfile` file:

```
gem "ff-ruby-server-sdk"
```

Here are complete example sthat will connect to the feature flag service and report the flag value every 10 seconds until the connection is closed.  
Any time a flag is toggled from the feature flag service you will receive the updated value.

### SDK Version 1 Example ( Supports Ruby 2.7 up to, but not including, Ruby 3.0.)

```ruby
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

# Create a Feature Flag Client and wait for it to initialize
client = CfClient.instance
client.init(apiKey, ConfigBuilder.new.logger(logger).build)
client.wait_for_initialization(timeout_ms: 20000) # timeout_ms is optional. 

# Create a target (different targets can get different results based on rules.  This include a custom attribute 'location')
target = Target.new("RubySDK", "rubysdk", {"location": "emea"})

# Loop forever reporting the state of the flag
loop do
  result = client.bool_variation(flagName, target, false)
  logger.info "Flag variation:  #{result}"
  sleep 10
end

client.close
```

### SDK Version 2 Example (for Ruby 3.0 and later)
```ruby
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

# Create a Feature Flag Client and wait for it to initialize
client = CfClient.instance
client.init(api_key: apiKey, config: ConfigBuilder.new.logger(logger).build)
client.wait_for_initialization(timeout_ms: 20000) # timeout_ms is optional. 

# Create a target (different targets can get different results based on rules.  This include a custom attribute 'location')
target = Target.new(identifier: "RubySDK", name: "rubysdk", attributes: {"location": "emea"})

# Loop forever reporting the state of the flag
loop do
  flag_value = client.bool_variation(identifier: flagName, target: target, default_value: false)
  logger.info "Flag variation:  #{result}"
  sleep 10
end

client.close
```

### Running the example

```bash
# Install the deps
gem install ff-ruby-server-sdk typhoeus

# Set your API Key
export FF_API_KEY=<your key here>

# Run the example
ruby ./example/getting_started/getting_started.rb
```

### Running with docker
If you don't have the right version of ruby installed locally, or don't want to install the dependencies you can
use docker to quickly get started

```bash
# Install the package
docker run -v $(pwd):/app -w /app -e FF_API_KEY=$FF_API_KEY ruby:2.7-buster gem install --install-dir ./gems ff-ruby-server-sdk typhoeus

# Run the script
docker run -v $(pwd):/app -w /app -e FF_API_KEY=$FF_API_KEY -e GEM_HOME=/app/gems ruby:2.7-buster ruby ./example/getting_started/getting_started.rb
```

### Additional Reading

Further examples and config options are in the further reading section:

[Further Reading](docs/further_reading.md)

[Ruby on Rails example](ruby_on_rails_example/README.md)

-------------------------
[Harness](https://www.harness.io/) is a feature management platform that helps teams to build better software and to
test features quicker.

-------------------------

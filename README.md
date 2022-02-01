Harness CF Ruby Server SDK
========================

## Overview

-------------------------
[Harness](https://www.harness.io/) is a feature management platform that helps teams to build better software and to
test features quicker.

-------------------------

## Setup

Add the following snippet to your project's `Gemfile` file:

```
gem "ff-ruby-server-sdk"
```

## Cloning the SDK repository

In order to clone SDK repository properly perform cloning like in the following example:

```
git clone --recurse-submodules git@github.com:harness/ff-ruby-server-sdk.git
```

After dependency has been added, the SDK elements, primarily `CfClient` should be accessible in the main application.

## Initialization

`CfClient` is a base class that provides all features of the SDK.

We can instantiate by calling the `instance` method or by using public
constructor (making multiple instances).

```ruby
require 'ff/ruby/server/sdk/api/config'
require 'ff/ruby/server/sdk/dto/target'
require 'ff/ruby/server/sdk/api/cf_client'
require 'ff/ruby/server/sdk/api/config_builder'

client = CfClient.instance

key = "YOUR_API_KEY_GOES_HERE"

logger = Logger.new(STDOUT)

# Or saving logs into the filesystem with daily rotation:
# logger = Logger.new("example.log", "daily")

config = ConfigBuilder.new
                      .logger(logger)
                      .build

client.init(key, config)

config.logger.debug 'We will wait for the initialization'

client.wait_for_initialization

config.logger.debug 'Initialization is complete'

target = Target.new("YOUR_TARGET_NAME")
```

`target` represents the desired target for which we want features to be evaluated.

`"YOUR_API_KEY"` is an authentication key, needed for access to Harness services.

**Your Harness SDK is now initialized. Congratulations!**

### Public API Methods ###

The Public API exposes a few methods that you can utilize:

Instantiate, initialize and close when done:

* `def initialize(api_key = nil, config = nil, connector = nil)`
* `def init(api_key = nil, config = nil, connector = nil)`
* `def wait_for_initialization`
* `def close`

Evaluations:

* `def bool_variation(identifier, target, default_value)`
* `def string_variation(identifier, target, default_value)`
* `def number_variation(identifier, target, default_value)`
* `def json_variation(identifier, target, default_value)`

## Fetch evaluation's value

It is possible to fetch a value for a given evaluation. Evaluation is performed based on a different type. In case there
is no evaluation with provided id, the default value is returned.

Use the appropriate method to fetch the desired Evaluation of a certain type.

### Bool variation

```
bool_result = client.bool_variation(bool_flag, target, false)  
```

### Number variation

```
number_result = client.number_variation(number_flag, target, -1)  
```

### String variation

```
string_result = client.string_variation(string_flag, target, "unavailable !!!")  
```

### JSON variation

```
json_result = client.json_variation(json_flag, target, JSON.parse("{}"))
```

## Using feature flags metrics

Metrics API endpoint can be changed like this (if ever needed):

```
config = ConfigBuilder.new
                      .event_url("SOME_ENDPOINT_URL")
                      .build
```

Otherwise, the default metrics endpoint URL will be used.

## Connector

This is a new feature that allows you to create or use other connectors.
Connector is just a proxy to your data. Currently supported connectors:

* Harness
* Local (used only in development)

```
connector = YourConnectorImplementation.new

client.init(

  key,
  config,
  connector
)
```

## Shutting down the SDK

To avoid potential memory leak, when SDK is no longer needed
(when the app is closed, for example), a caller should call this method:

```
client.close
```




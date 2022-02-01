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

`CfClient` is a base class that provides all features of SDK.

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

Tbd.



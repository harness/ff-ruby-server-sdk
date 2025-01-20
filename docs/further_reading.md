# Further Reading

Covers advanced topics (different config options and scenarios)

## Configuration Options
The following configuration options are available to control the behaviour of the SDK.
You can provide options by passing them in when the client is created e.g.

```ruby
client.init(apiKey, ConfigBuilder
                      .config_url("https://config.ff.harness.io/api/1.0")
                      .event_url("https://events.ff.harness.io/api/1.0")
                      .poll_interval_in_seconds(60)
                      .analytics_enabled(true)
                      .stream_enabled(true)
                      .build)
```

| Name            | Config Option                                      | Description                                                                                                                                      | default                              |
|-----------------|----------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------|
| baseUrl         | config_url("https://config.ff.harness.io/api/1.0") | the URL used to fetch feature flag evaluations. You should change this when using the Feature Flag proxy to http://localhost:7000                | https://config.ff.harness.io/api/1.0 |
| eventsUrl       | event_url("https://events.ff.harness.io/api/1.0"), | the URL used to post metrics data to the feature flag service. You should change this when using the Feature Flag proxy to http://localhost:7000 | https://events.ff.harness.io/api/1.0 |
| pollInterval    | poll_interval_in_seconds(60)                       | when running in stream mode, the interval in seconds that we poll for changes.                                                                   | 60                                   |
| enableStream    | analytics_enabled(false)                           | Enable streaming mode.                                                                                                                           | true                                 |
| enableAnalytics | stream_enabled(true)                               | Enable analytics.  Metrics data is posted every 60s                                                                                              | true                                 |

## Client Initialization Options
The Harness Feature Flags SDK for Ruby provides flexible initialization strategies to accommodate various application requirements. You can choose between an asynchronous (non-blocking) or synchronous (blocking) approach to initialize the SDK.

### Asynchronous (Non-Blocking) Initialization
The SDK can be initialized asynchronously without blocking the main thread or requiring a callback. In this case, defaults will be served until the SDK completes the initialization process.

```ruby
client = CfClient.instance
client.init(api_key, config)

# Will serve default until the SDK completes initialization
result = client.bool_variation("bool_flag", target, false)
```

### Synchronous (Blocking) Initialization

In cases where it's critical to ensure the SDK is initialized before evaluating flags, the SDK offers a synchronous initialization method. This approach blocks the current thread until the SDK is fully initialized or the optional specified timeout (in milliseconds) period elapses.

The synchronous method is useful for environments where feature flag decisions are needed before continuing, such as during application startup.

You can use the `wait_for_initialization` method, optionally providing a timeout in milliseconds to prevent waiting indefinitely in case of unrecoverable isues, e.g. incorrect API key used.

**Usage without a timeout**

```ruby
client = CfClient.instance
client.init(api_key, config)

client.wait_for_initialization

result = client.bool_variation("bool_flag", target, false)
```

**Usage with a timeout**

```ruby
client = CfClient.instance
client.init(api_key, config)

# Only wait for 30 seconds, after which if the SDK has not initialized the call will
# unblock and the SDK will then serve defaults
client.wait_for_initialization(timeout_ms: 30000)

result = client.bool_variation("bool_flag", target, false)
```

## Logging Configuration
You can provide your own logger to the SDK i.e. using the moneta logger we can do this

```ruby
require "logger"

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG
client.init(apiKey, ConfigBuilder.new.logger(logger).build)
```


## Recommended reading

[Feature Flag Concepts](https://ngdocs.harness.io/article/7n9433hkc0-cf-feature-flag-overview)

[Feature Flag SDK Concepts](https://ngdocs.harness.io/article/rvqprvbq8f-client-side-and-server-side-sdks)

## Setting up your Feature Flags

[Feature Flags Getting Started](https://ngdocs.harness.io/article/0a2u2ppp8s-getting-started-with-feature-flags)

### Public API Methods ###

The Public API exposes a few methods that you can utilize:

Instantiate, initialize, check if initialized and close when done:

* `def initialize(api_key = nil, config = nil, connector = nil)`
* `def initialized`
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

## Shutting down the SDK

To avoid potential memory leak, when SDK is no longer needed
(when the app is closed, for example), a caller should call the `close` method:

```
client.close
```

## Change default URL

When using your Feature Flag SDKs with a [Harness Relay Proxy](https://ngdocs.harness.io/article/q0kvq8nd2o-relay-proxy) you need to change the default URL.


```
config = ConfigBuilder.new
                      .config_url("https://config.feature-flags.uat.harness.io/api/1.0")
                      .event_url("https://event.feature-flags.uat.harness.io/api/1.0")
                      .build
```



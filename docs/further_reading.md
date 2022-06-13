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



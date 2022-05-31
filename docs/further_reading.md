# Further Reading

Covers advanced topics (different config options and scenarios)

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



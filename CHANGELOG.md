# [1.2.0] ** BREAKING **

- [FFM-9804] - The percentage rollout hash algorithm was slightly different compared to other Feature Flags SDKs, which resulted 
in a different bucket allocation for the same target. While the overall percentage distribution was correct with the previous
algorithm; this fix ensures that the same target will get the same allocation per SDK. We are marking as a breaking change
as existing targets may get different allocations in a percentage rollout flag. 

# [1.1.0]

- [FFM-7285] - Remove Metrics queue and implement Map for better memory usage
- [FFM-7325] - Improve authentication retry logic
- [FFM-6926] - Add basic Ruby on Rails example
- [FFM-6965] - Fixes analytics_enabled(false) which didn't fully turn off metrics
- [FFM-7005] - Add TLS support custom CAs and remove sse-client
- [FFM-7292] - Add HTTP headers for diagnostics

# [1.0.6]

- [FFM-3715] - Updates open api dependency issue

# [1.0.5]

- [FFM-6362] - Ruby FF SDK is not waiting initialization when using "wait_for_initialization" method

# [1.0.4]

- [FFM-5478] Fixes bug caching some flags due to encoding

# [1.0.3]

- [FFM-4058] Fixes bug in storing target segments
- [FFM-4755] Fixes multi-variate number variation to return floats instead of int
- [FFM-5355] Fixes bug in pre-requisite evaluation
- [FFM-5354] Fixes compatibility with Ruby-2.6

# [1.0.2]

- Runtime and development dependencies specified.

# [1.0.1]

- OpenAPI issues fixed

# [1.0.0]

- The first SDK release

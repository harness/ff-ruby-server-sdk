

# [1.4.9]
# [1.4.8]

- [FFM-12573] - Testing Harness Code release flow. No code changes

# [1.4.8]

- [FFM-12573] - Migrate build & release pipeline to Harness Code

# [1.4.7]

- [FFM-12713] - Limit number of targets in single payload

# [1.4.6]

- [FFM-12281] - Thread safety fixes
- [FFM-12277] - Add initialised method

# [1.4.5]

- [FM-12192] - Following from 1.4.4: Resolves an issue where Segmentation faults can occur on Ruby 3.4 and above

# [1.4.4]

- [FFM-12192] - Following from 1.4.3, we are still investigating an edge case in the SDK, where segmentation faults can occur when the SDK aggregates and sends metrics at the end of an interval:
- [FFM-12192] - Also fixes some behaviour around default variations being returned

# [1.4.3]
# [1.4.2]

- [FFM-12192] - Following from 1.4.2, we are still investigating an edge case in the SDK, where very large projects can generate invalid metric events shortly after the SDK has initialised. This patch includes possible fixes for this issue.

# [1.4.1]

- [FFM-12192] - Skips processing invalid metrics if they are detected.

# [1.4.0]

- [FFM-12088] - Adds an optional timeout parameter for wait_for_initialization,

# [1.3.2]

- [FFM-11995] - No longer ships rake minitest and standard as dependencies.

# [1.3.1]

- [FFM-11657] - Sort group AND/OR rules and Flag rules when caching group instead of during an evaluation call

# [1.3.0]

- [FFM-11241] - Target v2: Adding SDK support for AND/OR rules.
- [FFM-11365] - Add rules-v2 query parameter to optimise the rules that the FF backend sends for AND/OR rules.
- [FFM-11211] - Metrics fixes

# [1.2.1]

- [FFM-10177] - Ruby SDK - Use pessimistic version operator for minor versions

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

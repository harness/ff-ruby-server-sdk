# Building ff-ruby-server-sdk

This document shows the instructions on how to build and contribute to the SDK.

## Requirements
[Ruby 2.7](https://www.ruby-lang.org/en/documentation/installation/) or newer (ruby --version)<br>
[openapi-generator-cli](https://openapi-generator.tech/docs/installation/)
## Cloning the SDK repository
In order to clone SDK repository properly perform cloning like in the following example:
```
git clone --recurse-submodules git@github.com:harness/ff-ruby-server-sdk.git
```

## Install Dependencies
```bash
npm install @openapitools/openapi-generator-cli -g
npm install @openapitools/openapi-generator-cli -D
bundle install
```

## Build the SDK
```bash
gem build ff-ruby-server-sdk.gemspec
```

#!/usr/bin/env bash

ruby -v
apt-get update
apt-get install -y npm
apt-get install -y maven
apt-get install -y jq
mvn --version
npm install @openapitools/openapi-generator-cli -g
npm install @openapitools/openapi-generator-cli -D
gem install minitest-junit
sh scripts/install.sh
gem env
gem install ff-ruby-server-sdk typhoeus
ruby test/ff/ruby/server/sdk/sdk_test.rb --junit

#!/bin/bash

sdk="ff-ruby-server-sdk"

gem build "$sdk.gemspec" && sudo gem install "$sdk"
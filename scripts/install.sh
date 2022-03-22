#!/bin/bash

full_path=$(realpath "$0")
dir_path=$(dirname "$full_path")

. "$dir_path/sdk_specs.sh"

# shellcheck disable=SC2154
if cd "$dir_path/.." && gem build "$ff_ruby_sdk.gemspec" && gem install "$ff_ruby_sdk"; then

  echo "SUCCESS: Installed"
else

  echo "ERROR: FF Gem not installed"
  exit 1
fi
#!/bin/bash

full_path=$(realpath "$0")
dir_path=$(dirname "$full_path")

. "$dir_path/sdk_specs.sh"

# shellcheck disable=SC2154
if cd "$dir_path/.." && gem build "$ff_ruby_sdk.gemspec" && gem install "$ff_ruby_sdk"; then

  echo "$ff_ruby_sdk installed with success"
else

  echo "ERROR: $ff_ruby_sdk not installed"
  exit 1
fi
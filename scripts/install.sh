#!/bin/bash

full_path=$(realpath "$0")
dir_path=$(dirname "$full_path")

. "$dir_path/sdk_specs.sh"

# shellcheck disable=SC2154
if cd "$dir_path/.." && gem build "$ff_ruby_sdk.gemspec" && gem install "$ff_ruby_sdk"; then

  echo "The '$ff_ruby_sdk' is installed with success"
else

  echo "ERROR: the '$ff_ruby_sdk' is NOT installed with success"
  exit 1
fi
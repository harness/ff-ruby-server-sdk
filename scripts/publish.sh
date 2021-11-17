#!/bin/bash

full_path=$(realpath "$0")
dir_path=$(dirname "$full_path")

. "$dir_path/sdk_specs.sh"

# shellcheck disable=SC2154
if cd "$dir_path/.." && gem build "$ff_ruby_sdk.gemspec"; then

  if echo "Please enter your 'sudo' password if asked" && sudo gem install "$ff_ruby_sdk"; then

    gem push "$ff_ruby_sdk-$ff_ruby_sdk_version.gem"
  else

    exit 1
  fi
else

  exit 1
fi

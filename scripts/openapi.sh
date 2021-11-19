#!/bin/bash

full_path=$(realpath "$0")
dir_path=$(dirname "$full_path")

. "$dir_path/sdk_specs.sh"

if which openapi-generator; then

  cd "$dir_path/.." && \
    openapi-generator generate -i api.yaml -g ruby -o ./lib/ff/ruby/server/generated
else

  echo "ERROR: 'openapi-generator' is not installed"
  exit 1
fi

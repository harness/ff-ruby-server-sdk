#!/bin/bash

full_path=$(realpath "$0")
dir_path=$(dirname "$full_path")

. "$dir_path/sdk_specs.sh"

# shellcheck disable=SC2154
gem yank -v "$ff_ruby_sdk_version" "$ff_ruby_sdk"

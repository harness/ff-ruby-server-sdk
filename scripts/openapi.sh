#!/bin/bash

full_path=$(realpath "$0")
dir_path=$(dirname "$full_path")

. "$dir_path/sdk_specs.sh"

if which openapi-generator; then

  generated_path="$dir_path/../generated"

  if test -e "$generated_path"; then

    if rm -rf "$generated_path"; then

      echo "'$generated_path' was removed with success 🙂"
    else

      echo "ERROR: '$$generated_path' was not removed before the generation process 😬"
      exit 1
    fi
  fi

  cd "$dir_path/.." &&
    openapi-generator generate -i api.yaml -g ruby -o generated &&
    cd "$generated_path" && gem build openapi_client.gemspec && cd .. &&
    echo "Please enter your 'sudo' password if asked" &&
    sudo gem install "$generated_path/openapi_client-1.0.0.gem" &&
    echo "Generated API has been installed with success 🤟"

else

  echo "ERROR: 'openapi-generator' is not installed 😬"
  exit 1
fi

#!/bin/bash

full_path=$(realpath "$0")
dir_path=$(dirname "$full_path")

if [ -z "$1" ]
  then

    installation_path="$dir_path/../lib/ff/ruby/server/generated"
    echo "No installation has been provided, using the default path: $installation_path"
else

    installation_path="$1"
    echo "Installation path provided: $installation_path"
fi


. "$dir_path/sdk_specs.sh"

if which openapi-generator-cli; then

  generated_path="$installation_path"

  if test -e "$generated_path"; then

    if rm -rf "$generated_path"; then

      echo "'$generated_path' was removed with success 🙂"
    else

      echo "ERROR: '$generated_path' was not removed before the generation process 😬"
      exit 1
    fi
  else

    if mkdir -p "$generated_path" && test -e "$generated_path"; then

      echo "'$generated_path' has been created with success 🙂"
    else

      echo "ERROR: '$generated_path' was not created with success 😬"
      exit 1
    fi
  fi

  if  gem install rspec-expectations -v 3.12.0 && \
      gem install rspec-mocks -v 3.12.0 && \
      gem install rake -v 13.0 && \
      gem install minitest -v 5.15.0 && \
      gem install standard -v 1.11.0 && \
      gem install pp -v 0.3.0 && \
      gem install libcache -v 0.4.2 && \
      gem install rufus-scheduler -v 3.8.1 && \
      gem install jwt -v 2.3.0 && \
      gem install moneta -v 1.4.2 && \
      gem install rest-client -v 2.1.0 && \
      gem install sse-client -v 1.1.0 && \
      gem install concurrent-ruby -v 1.1.10 && \
      gem install murmurhash3 -v 0.1.6 && \
      cd "$dir_path/.." && \
      openapi-generator-cli generate -i api.yaml -g ruby -o "$generated_path" && \
      cd "$generated_path" && gem build openapi_client.gemspec && \
      test -e "openapi_client-1.0.0.gem" && \
      gem install --dev "openapi_client-1.0.0.gem"; then

      echo "Generated API has been installed with success: $generated_path"
  else

      echo "ERROR: 'openapi-generator-cli' is not installed [1] 😬"
      exit 1
  fi
else

  echo "ERROR: 'openapi-generator-cli' is not installed [2] 😬"
  exit 1
fi

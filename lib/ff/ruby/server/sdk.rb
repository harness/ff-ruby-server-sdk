# frozen_string_literal: true

require_relative "sdk/version"

require_relative "sdk/common/cache"
require_relative "sdk/common/storage"
require_relative "sdk/common/closeable"
require_relative "sdk/common/repository"
require_relative "sdk/common/destroyable"

require_relative "sdk/api/config"
require_relative "sdk/api/operators"
require_relative "sdk/api/cf_client"
require_relative "sdk/api/inner_client"
require_relative "sdk/api/auth_service"
require_relative "sdk/api/default_cache"
require_relative "sdk/api/config_builder"
require_relative "sdk/api/file_map_store"
require_relative "sdk/api/client_callback"
require_relative "sdk/api/storage_repository"

require_relative "sdk/connector/connector"
require_relative "sdk/connector/event_source"
require_relative "sdk/connector/harness_connector"

module Ff
  module Ruby
    module Server
      module Sdk

      end
    end
  end
end

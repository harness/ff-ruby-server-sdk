# frozen_string_literal: true

require_relative "sdk/version"

require_relative "sdk/common/cache"
require_relative "sdk/common/storage"
require_relative "sdk/common/closeable"
require_relative "sdk/common/repository"
require_relative "sdk/common/destroyable"

require_relative "sdk/dto/target"
require_relative "sdk/dto/message"

require_relative "sdk/api/config"
require_relative "sdk/api/operators"
require_relative "sdk/api/cf_client"
require_relative "sdk/api/evaluation"
require_relative "sdk/api/inner_client"
require_relative "sdk/api/auth_service"
require_relative "sdk/api/metrics_event"
require_relative "sdk/api/default_cache"
require_relative "sdk/api/config_builder"
require_relative "sdk/api/file_map_store"
require_relative "sdk/api/client_callback"
require_relative "sdk/api/update_processor"
require_relative "sdk/api/metrics_callback"
require_relative "sdk/api/metrics_processor"
require_relative "sdk/api/polling_processor"
require_relative "sdk/api/storage_repository"
require_relative "sdk/api/repository_callback"
require_relative "sdk/api/inner_client_updater"
require_relative "sdk/api/flag_evaluate_callback"
require_relative "sdk/api/inner_client_repository_callback"
require_relative "sdk/api/inner_client_flag_evaluate_callback"

require_relative "sdk/connector/updater"
require_relative "sdk/connector/service"
require_relative "sdk/connector/connector"
require_relative "sdk/connector/events"
require_relative "sdk/connector/harness_connector"
require_relative "sdk/connector/connector_exception"

module Ff
  module Ruby
    module Server
      module Sdk

      end
    end
  end
end

require_relative "inner_client"
require_relative "repository_callback"

class InnerClientRepositoryCallback < RepositoryCallback

  def initialize(logger)

    if logger != nil

      @logger = logger
    else

      @logger = Logger.new(STDOUT)
    end
  end

  def on_flag_stored(identifier)

    @logger.debug "On flag stored: " + identifier

    # TODO: Notify consumers
  end

  def on_flag_deleted(identifier)

    @logger.debug "On flag deleted: " + identifier

    # TODO: Notify consumers
  end

  def on_segment_stored(identifier)

    @logger.debug "On segment stored: " + identifier

    # TODO: Notify consumers
  end

  def on_segment_deleted(identifier)

    @logger.debug "On segment deleted: " + identifier

    # TODO: Notify consumers
  end
end
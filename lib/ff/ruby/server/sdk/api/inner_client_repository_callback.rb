require_relative "inner_client"
require_relative "repository_callback"

class InnerClientRepositoryCallback < RepositoryCallback

  def initialize
    super

  end

  def on_flag_stored(identifier)

    puts "On flag stored: " + identifier

    # TODO: Notify consumers
  end

  def on_flag_deleted(identifier)

    puts "On flag deleted: " + identifier

    # TODO: Notify consumers
  end

  def on_segment_stored(identifier)

    puts "On segment stored: " + identifier

    # TODO: Notify consumers
  end

  def on_segment_deleted(identifier)

    puts "On segment deleted: " + identifier

    # TODO: Notify consumers
  end
end
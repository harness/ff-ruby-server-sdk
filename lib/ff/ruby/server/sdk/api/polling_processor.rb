class PollingProcessor

  def initialize(

    connector,
    repository,
    poll_interval_in_sec,
    callback
  )

    @connector = connector
    @repository = repository
    @poll_interval_in_sec = poll_interval_in_sec
    @callback = callback
  end

end
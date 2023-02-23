module ExampleHelper

  def make_ff_client
    $stdout.sync = true
    logger = Logger.new $stdout
    logger.level = 'info'


    api_key = ENV['FF_API_KEY'] || 'changeme'

    client = CfClient.instance
    client.init(api_key, ConfigBuilder.new.logger(logger).build)
    client.wait_for_initialization

    logger.info "---- CfClient ready ----"

    client
  end

  # Use this to access the CfClient.instance - it will make sure it's only instantiated once
  def get_ff_client
    @@ff_client ||= make_ff_client

    @@ff_client
  end


  # A helper method that gets and logs the flag state
  def get_bool_flag(flag_name, target, default)
    value = get_ff_client.bool_variation(flag_name, target, default)

    logger.info "FLAG %s ---> %s" % [flag_name, value]

    value
  end

end

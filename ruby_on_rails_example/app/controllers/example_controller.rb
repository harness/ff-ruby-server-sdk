class ExampleController < ApplicationController

  def index
    @flag_name = ENV['FF_FLAG_NAME'] || 'harnessappdemodarkmode'
    @target = Target.new("RubyOnRailsExample", identifier="rubysdk", attributes={"username": "test"})
  end
end

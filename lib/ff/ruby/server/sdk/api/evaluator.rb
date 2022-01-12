require_relative "evaluation"
require_relative "../common/repository"

class Evaluator < Evaluation

  def initialize(repository)

    unless repository.kind_of?(Repository)

      raise "The 'repository' parameter must be of '" + Repository.to_s + "' data type"
    end

    @repository = repository
  end

  def bool_variation(identifier, target, default_value, callback)


  end

  def string_variation(identifier, target, default_value, callback)


  end

  def number_variation(identifier, target, default_value, callback)


  end

  def json_variation(identifier, target, default_value, callback)


  end
end
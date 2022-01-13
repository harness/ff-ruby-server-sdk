require "json"

require_relative "evaluation"
require_relative "../common/repository"

class Evaluator < Evaluation

  def initialize(repository)

    unless repository.kind_of?(Repository)

      raise "The 'repository' parameter must be of '" + Repository.to_s + "' data type"
    end

    @one_hundred = 100

    @repository = repository
  end

  def bool_variation(identifier, target, default_value, callback)

    val variation = evaluate(identifier, target, "boolean", callback)

    if variation != nil

      return variation.value == "true"
    end

    default_value
  end

  def string_variation(identifier, target, default_value, callback)

    val variation = evaluate(identifier, target, "string", callback)

    if variation != nil

      return variation.value
    end

    default_value
  end

  def number_variation(identifier, target, default_value, callback)

    val variation = evaluate(identifier, target, "int", callback)

    if variation != nil

      return variation.value.to_i
    end

    default_value
  end

  def json_variation(identifier, target, default_value, callback)

    val variation = evaluate(identifier, target, "json", callback)

    if variation != nil

      return JSON.parse(variation.value)
    end

    default_value
  end

  def evaluate(identifier, target, expected, callback)

    unless callback.kind_of?(FlagEvaluateCallback)

      raise "The 'callback' parameter must be of '" + FlagEvaluateCallback.to_s + "' data type"
    end

    val flag = @repository.get_flag(identifier)

    if flag != nil && flag.kind == expected

      unless flag.prerequisites.empty

        pre_req = check_pre_requisite(flag, target)

        unless pre_req

          return find_variation(flag.variations, flag.off_variation)
        end
      end

      variation = evaluate_flag(flag, target)

      if variation != nil

        if callback != nil

          callback.process_evaluation(flag, target, variation)
        end

        return variation
      end
    end

    nil
  end

  protected

  def get_attr_value(target, attribute) end

  def find_variation(variations, identifier) end

  def get_normalized_number(property, bucket_by) end

  def is_enabled(target, bucket_by, percentage) end

  def evaluate_distribution(distribution, target) end

  def evaluate_clauses(clauses, target) end

  def evaluate_clause(clause, target) end

  def is_target_included_or_excluded_in_segment(segment_list, target) end

  def evaluate_rules(serving_rules, target) end

  def evaluate_rule(serving_rule, target) end

  def evaluate_variation_map(variation_maps, target) end

  def evaluate_flag(feature_config, target) end

  def check_pre_requisite(parent_feature_config, target) end

  private

  def is_target_in_list(target, list_of_target) end
end
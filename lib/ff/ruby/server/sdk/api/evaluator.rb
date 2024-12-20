require "json"
require "murmurhash3"

require_relative "evaluation"
require_relative "../common/repository"
require_relative "../common/sdk_codes"

class Evaluator < Evaluation

  def initialize(repository, logger = nil)

    unless repository.kind_of?(Repository)
      raise "The 'repository' parameter must be of '" + Repository.to_s + "' data type"
    end

    if logger != nil
      @logger = logger
    else
      @logger = Logger.new(STDOUT)
    end

    @repository = repository
  end

  def bool_variation(identifier, target, default_value, callback)

    variation = evaluate(identifier, target, "boolean", callback)

    if variation != nil
      return variation.value == "true"
    end

    SdkCodes::warn_default_variation_served @logger, identifier, target, default_value.to_s
    default_value
  end

  def string_variation(identifier, target, default_value, callback)

    variation = evaluate(identifier, target, "string", callback)

    if variation != nil
      return variation.value
    end

    SdkCodes::warn_default_variation_served @logger, identifier, target, default_value.to_s
    default_value
  end

  def integer_variation(identifier, target, default_value, callback)

    variation = evaluate(identifier, target, "int", callback)

    if variation != nil
      return variation.value.to_i
    end

    SdkCodes::warn_default_variation_served @logger, identifier, target, default_value.to_s
    default_value
  end

  def number_variation(identifier, target, default_value, callback)
    variation = evaluate(identifier, target, "int", callback)

    if variation != nil
      return variation.value.to_f
    end

    SdkCodes::warn_default_variation_served @logger, identifier, target, default_value.to_s
    default_value
  end

  def json_variation(identifier, target, default_value, callback)

    variation = evaluate(identifier, target, "json", callback)

    if variation != nil
      return JSON.parse(variation.value)
    end

    SdkCodes::warn_default_variation_served @logger, identifier, target, default_value.to_s
    default_value
  end

  def evaluate(identifier, target, expected, callback)

    if callback != nil
      unless callback.kind_of?(FlagEvaluateCallback)
        raise "The 'callback' parameter must be of '" + FlagEvaluateCallback.to_s + "' data type"
      end
    end

    flag = @repository.get_flag(identifier)

    # Check if flag exists
    if flag.nil?
      # Log a warning if the flag is not found
      @logger.warn "Flag not found for identifier '#{identifier}'. Serving default variation."
      return nil
    end

    # Check if the flag's kind matches the expected type
    unless flag.kind == expected
      @logger.warn "Flag kind mismatch: expected '#{expected}', but got '#{flag.kind}' for identifier '#{identifier}'. Serving default variation."
      return nil
    end

    # Proceed with prerequisite check if flag type is as expected
    if flag != nil && flag.kind == expected
      unless flag.prerequisites.empty?
        pre_req = check_pre_requisite(flag, target)
        unless pre_req
          return find_variation(flag.variations, flag.off_variation)
        end
      end

      variation = evaluate_flag(flag, target)

      if variation != nil
        if callback != nil
          feature_name = flag.feature
          variation_identifier = variation.identifier
          callback.process_evaluation(feature_name, target, variation_identifier)
        end
        return variation
      end
    end

    # Returning nil will indicate to callers to serve the default variation
    nil
  end

  protected

  def get_attr_value(target, attribute)

    if attribute != nil && !attribute.empty?
      if target.respond_to?(attribute, :include_private)
        @logger.debug "The attribute " + attribute.to_s + " exists (1)"
        return target.send(attribute)
      else

        @logger.debug "target attrs: " + target.attributes.to_s
        result = target.attributes[attribute.to_sym]
        if result == nil
          @logger.debug "The attribute " + attribute.to_s + " does not exist"
        else
          @logger.debug "The attribute " + attribute.to_s + " exists (2)"
        end

        return result
      end
    end

    @logger.debug "The passed attribute is empty"

    nil
  end

  def find_variation(variations, identifier)

    if identifier != nil && !identifier.empty?
      variations.each do |v|
        if v.identifier == identifier
          return v
        end
      end
    end

    nil
  end

  def get_normalized_number(property, bucket_by)
    joined = bucket_by.to_s + ":" + property.to_s
    hash = MurmurHash3::V32.str_hash(joined, 0)
    (hash % 100) + 1
  end

  def is_enabled(target, bucket_by, percentage)
    property = get_attr_value(target, bucket_by)

    if property == nil
      old_bb = bucket_by
      bucket_by = "identifier"
      property = get_attr_value(target, bucket_by)
      SdkCodes.warn_bucket_by_attr_not_found @logger, old_bb, property
    end

    if property != nil
      bucket_id = get_normalized_number(property, bucket_by)
      @logger.debug "MM3 percentage_check=%s bucket_by=%s value=%s bucket=%s" % [percentage, bucket_by, property, bucket_id]
      return percentage > 0 && bucket_id <= percentage
    end

    false
  end

  def evaluate_distribution(distribution, target)

    if distribution != nil

      variation = nil
      total_percentage = 0
      distribution.variations.each do |weighted_variation|
        variation = weighted_variation.variation
        total_percentage = total_percentage + weighted_variation.weight
        if is_enabled(target, distribution.bucket_by, total_percentage)
          return variation
        end
      end

      return variation
    end

    nil
  end


  def evaluate_clauses_v2(clauses, target)
    if clauses.empty?
      return false
    end

    # New style rules require that all clauses are true
    clauses.each do |clause|
      if !evaluate_clause(clause, target)
        return false
      end
    end
    true
  end

  def evaluate_clauses(clauses, target)

    clauses.each do |clause|

      if evaluate_clause(clause, target)
        return true
      end
    end

    false
  end

  def evaluate_clause(clause, target)

    if clause == nil
      return false
    end

    operator = clause.op

    if operator == nil || operator.empty?
      return false
    end

    if operator == "segmentMatch"
      return is_target_included_or_excluded_in_segment(clause.values, target)
    end

    if clause.values.empty?
      return false
    end

    value = clause.values[0]
    attr_value = get_attr_value(target, clause.attribute)

    if attr_value == nil
      return false
    end

    object = attr_value.to_s

    if operator == "starts_with"
      return object.start_with?(value)
    end

    if operator == "ends_with"
      return object.end_with?(value)
    end

    if operator == "match"
      match = object.match?(value)
      return match != nil && !match.empty?
    end

    if operator == "contains"
      return object.include?(value)
    end

    if operator == "equal"
      return object.casecmp?(value)
    end

    if operator == "equal_sensitive"
      return object == value
    end

    if operator == "in"
      return clause.values.include?(object)
    end

    if operator == "segmentMatch"
      return is_target_included_or_excluded_in_segment(clause.values, target)
    end

    false
  end

  def is_target_included_or_excluded_in_segment(segment_list, target)

    segment_list.each do |segment_identifier|

      segment = @repository.get_segment(segment_identifier)

      if segment != nil

        if is_target_in_list(target, segment.excluded)
          @logger.debug "Target " + target.name.to_s + " excluded from segment " + segment.name.to_s + " via exclude list"
          return false
        end

        if is_target_in_list(target, segment.included)
          @logger.debug "Target " + target.name.to_s + " included in segment " + segment.name.to_s + " via include list"
          return true
        end

        new_serving_rules = segment.serving_rules
        if new_serving_rules != nil && !new_serving_rules.empty?
          # Use enhanced rules first if they're available

          new_serving_rules.each do |serving_rule|
            if evaluate_clauses_v2(serving_rule.clauses, target)
              return true
            end
          end

        else
          # Fall back to old rules
          rules = segment.rules
          if rules != nil && !rules.empty? && evaluate_clauses(rules, target)
            @logger.debug "Target " + target.name.to_s + " included in segment " + segment.name.to_s + " via rules"
            return true
          end
        end

      end
    end

    false
  end

  def evaluate_rules(serving_rules, target)

    if target == nil || serving_rules == nil
      return nil
    end

    serving_rules.each do |rule|
      next unless evaluate_rule(rule, target)

      if rule.serve.distribution != nil
        return evaluate_distribution(rule.serve.distribution, target)
      end

      if rule.serve.variation != nil
        return rule.serve.variation
      end
    end

    nil
  end

  def evaluate_rule(serving_rule, target)
    evaluate_clauses(serving_rule.clauses, target)
  end

  def evaluate_variation_map(variation_maps, target)

    if target == nil
      return nil
    end

    variation_maps.each do |variation_map|

      targets = variation_map.targets

      if targets != nil
        found = nil
        targets.each do |t|
          if t.identifier != nil && t.identifier == target.identifier
            found = t
            break
          end
        end

        if found != nil
          return variation_map.variation
        end
      end

      segment_identifiers = variation_map.target_segments

      if segment_identifiers != nil && is_target_included_or_excluded_in_segment(segment_identifiers, target)
        return variation_map.variation
      end
    end

    nil
  end

  def evaluate_flag(feature_config, target)

    variation = feature_config.off_variation

    if feature_config.state == OpenapiClient::FeatureState::ON
      variation = nil

      if feature_config.variation_to_target_map != nil
        variation = evaluate_variation_map(feature_config.variation_to_target_map, target)
      end

      if variation == nil
        variation = evaluate_rules(feature_config.rules, target)
      end

      if variation == nil
        variation = evaluate_distribution(feature_config.default_serve.distribution, target)
      end

      if variation == nil
        variation = feature_config.default_serve.variation
      end
    end

    if variation != nil
      return find_variation(feature_config.variations, variation)
    end

    nil
  end

  def check_pre_requisite(parent_feature_config, target)

    prerequisites = parent_feature_config.prerequisites

    if prerequisites != nil && !prerequisites.empty?
      @logger.debug "Checking prerequisite #{prerequisites.to_s} of flag #{parent_feature_config.feature}"

      prerequisites.each do |pre_req|
        pre_req_flag = @repository.get_flag(pre_req.feature)

        if pre_req_flag == nil
          @logger.debug "Could not retrieve the pre requisite details of feature flag: #{pre_req.feature}"
          return true
        end

        evaluated_pre_req = evaluate_flag(pre_req_flag, target)

        if evaluated_pre_req == nil
          @logger.debug "Could not evaluate the prerequisite details of feature flag: #{pre_req.feature}"
          return true
        end

        none_match = true
        pre_req.variations.each do |next_variation|
          if next_variation.include?(evaluated_pre_req.identifier)
            none_match = false
            break
          end
        end

        if none_match
          @logger.debug "Prerequisite flag #{pre_req_flag.feature} has no matching variations for flag #{parent_feature_config.feature}"
          return false
        else
          unless check_pre_requisite(pre_req_flag, target)
            @logger.debug "Prerequisite flag #{pre_req_flag.feature} is switched off for flag #{parent_feature_config.feature}"
            return false
          end
        end
      end # prerequisites.each

      @logger.debug "All prerequisite flags are switched on for flag #{parent_feature_config.feature}"
      return true
    end

    @logger.debug "No prerequisite flags present for flag #{parent_feature_config.feature}, skipped"
    true
  end

  private

  def is_target_in_list(target, list_of_targets)

    if list_of_targets != nil
      list_of_targets.each do |included_target|
        if included_target.identifier.include?(target.identifier)
          return true
        end
      end
    end

    false
  end
end

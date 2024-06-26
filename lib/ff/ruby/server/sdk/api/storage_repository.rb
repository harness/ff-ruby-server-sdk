require_relative "operators"
require_relative "repository_callback"
require_relative "../common/repository"

class StorageRepository < Repository

  def initialize(cache, callback = nil, store = nil, logger = nil)

    @cache = cache
    @store = store
    @callback = callback

    if logger != nil

      @logger = logger
    else

      @logger = Logger.new(STDOUT)
    end
  end

  def get_flag(identifier, cacheable = true)

    flag_key = format_flag_key(identifier)
    flag = @cache.get(flag_key)

    if flag != nil

      return flag
    end

    if @store != nil

      flag = @store.get(flag_key)
      if flag != nil && cacheable

        @cache.set(flag_key, flag)
      end

      return flag
    end

    nil
  end

  def get_segment(identifier, cacheable = true)

    segment_key = format_segment_key(identifier)
    segment = @cache.get(segment_key)

    if segment != nil

      return segment
    end

    if @store != nil

      segment = @store.get(segment_key)
      if segment != nil && cacheable

        @cache.set(segment_key, segment)
      end

      return segment
    end

    nil
  end

  def find_flags_by_segment(identifier)

    result = []
    keys = @cache.keys

    if @store != nil

      keys = @store.keys
    end

    keys.each do |key|

      flag = get_flag(key)

      if flag != nil && !flag.rules.length > 0

        flag.rules.each do |rule|

          rule.clauses.each do |clause|

            if clause.op == Operators.SEGMENT_MATCH && clause.values.include(identifier)

              result.push(flag.feature)
            end
          end
        end
      end
    end

    result
  end

  def set_flag(identifier, feature_config)

    if is_flag_outdated(identifier, feature_config)

      @logger.debug "Flag " + identifier + " already exists"
      return
    end

    sort_flag_rules(feature_config)
    flag_key = format_flag_key(identifier)

    if @store != nil

      @store.set(flag_key, feature_config)
      @cache.delete(flag_key)

      @logger.debug "Flag " + identifier + " successfully stored and cache invalidated"
    else

      @cache.set(flag_key, feature_config)

      @logger.debug "Flag " + identifier + " successfully cached"
    end

    if @callback != nil

      unless @callback.kind_of?(RepositoryCallback)

        raise "The 'callback' parameter must be of '" + RepositoryCallback.to_s + "' data type"
      end

      @callback.on_flag_stored(identifier)
    end
  end

  def set_segment(identifier, segment)

    if is_segment_outdated(identifier, segment)

      @logger.debug "Segment " + identifier + " already exists"
      return
    end

    sort_segment_serving_rules(segment)
    segment_key = format_segment_key(identifier)

    if @store != nil

      @store.set(segment_key, segment)
      @cache.delete(segment_key)

      @logger.debug "Segment " + identifier + " successfully stored and cache invalidated"
    else

      @cache.set(segment_key, segment)

      @logger.debug "Segment " + identifier + " successfully cached"
    end

    if @callback != nil

      unless @callback.kind_of?(RepositoryCallback)

        raise "The 'callback' parameter must be of '" + RepositoryCallback.to_s + "' data type"
      end

      @callback.on_segment_stored(identifier)
    end
  end

  def delete_flag(identifier)

    flag_key = format_flag_key(identifier)

    if @store != nil

      @store.delete(flag_key)

      @logger.debug "Flag " + identifier + " successfully deleted from store"
    end

    @cache.delete(flag_key)

    @logger.debug "Flag " + identifier + " successfully deleted from cache"

    if @callback != nil

      unless @callback.kind_of?(RepositoryCallback)

        raise "The 'callback' parameter must be of '" + RepositoryCallback.to_s + "' data type"
      end

      @callback.on_flag_deleted(identifier)
    end
  end

  def delete_segment(identifier)

    segment_key = format_segment_key(identifier)

    if @store != nil

      @store.delete(segment_key)

      @logger.debug "Segment " + identifier + " successfully deleted from store"
    end

    @cache.delete(segment_key)

    @logger.debug "Segment " + identifier + " successfully deleted from cache"

    if @callback != nil

      unless @callback.kind_of?(RepositoryCallback)

        raise "The 'callback' parameter must be of '" + RepositoryCallback.to_s + "' data type"
      end

      @callback.on_segment_deleted(identifier)
    end
  end

  def close

    if @store != nil

      @store.close
    end
  end

  protected

  def is_flag_outdated(identifier, new_feature_config)

    flag = get_flag(identifier, false)
    if flag != nil && flag.version != new_feature_config.version

      return flag.version >= new_feature_config.version
    end

    false
  end

  def sort_flag_rules(flag)
    if flag.rules && flag.rules.length > 1
      flag.rules.sort_by!(&:priority)
    end
  end

  def sort_segment_serving_rules(segment)
    if segment.serving_rules && segment.serving_rules.length > 1
      segment.serving_rules.sort_by!(&:priority)
    end
  end

  def is_segment_outdated(identifier, new_segment)

    segment = get_segment(identifier, false)
    if segment != nil && segment.version != new_segment.version

      return segment.version >= new_segment.version
    end

    false
  end

  def format_flag_key(identifier)

    "flags_" + identifier
  end

  def format_segment_key(identifier)

    "segments_" + identifier
  end
end
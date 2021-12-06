require_relative "../common/repository"

class StorageRepository < Repository

  def initialize(cache, store = nil, callback)

    @cache = cache
    @store = store
    @callback = callback
  end

  def get_flag(identifier)

    # TODO: Override
  end

  def get_segment(identifier)

    # TODO: Override
  end

  def find_flags_by_segment(identifier)

    # TODO: Override
  end

  def set_flag(identifier, feature_config)

    # TODO: Override
  end

  def set_segment(identifier, segment)

    # TODO: Override
  end

  def delete_flag(identifier)

    # TODO: Override
  end

  def delete_segment(identifier)

    # TODO: Override
  end
end
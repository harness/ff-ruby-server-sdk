require_relative "closeable"

class Repository < Closeable

  def initialize
    super

    @tbi = "To be implemented"
  end

  def get_flag(identifier, cacheable)

    raise @tbi
  end

  def get_segment(identifier, cacheable)

    raise @tbi
  end

  def find_flags_by_segment(identifier)

    raise @tbi
  end

  def set_flag(identifier, feature_config)

    raise @tbi
  end

  def set_segment(identifier, segment)

    raise @tbi
  end

  def delete_flag(identifier)

    raise @tbi
  end

  def delete_segment(identifier)

    raise @tbi
  end
end
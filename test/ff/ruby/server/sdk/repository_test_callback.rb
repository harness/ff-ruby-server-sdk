class RepositoryTestCallback < RepositoryCallback

  attr_accessor :on_flag_stored_count, :on_flag_deleted_count, :on_segment_stored_count, :on_segment_deleted_count

  def initialize
    super

    @on_flag_stored_count = 0
    @on_flag_deleted_count = 0
    @on_segment_stored_count = 0
    @on_segment_deleted_count = 0
  end

  def on_flag_stored(identifier)

    @on_flag_stored_count = @on_flag_stored_count + 1
  end

  def on_flag_deleted(identifier)

    @on_flag_deleted_count = @on_flag_deleted_count + 1
  end

  def on_segment_stored(identifier)

    @on_segment_stored_count = @on_segment_stored_count + 1
  end

  def on_segment_deleted(identifier)

    @on_segment_deleted_count = @on_segment_deleted_count + 1
  end
end
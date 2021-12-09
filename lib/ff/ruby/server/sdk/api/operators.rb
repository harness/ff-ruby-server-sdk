class Operators

  def initialize
    super

    raise "Abstract"
  end

  # Static:
  class << self

    @@SEGMENT_MATCH = "SEGMENT_MATCH"

    def SEGMENT_MATCH

      @@SEGMENT_MATCH
    end

  end # Static - End
end
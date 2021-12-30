class Target

  def initialize(

    name,
    identifier = name,
    attributes = [],
    is_private = false
  )

    @name = name
    @identifier = identifier
    @attributes = attributes
    @is_private = is_private
  end

  def is_valid

    @identifier != nil && !@identifier.strip.empty
  end
end
class Target

  attr_accessor :name, :identifier, :attributes, :is_private, :private_attributes

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
    @private_attributes = Set[]
  end

  def is_valid

    @identifier != nil && !@identifier.strip.empty?
  end
end
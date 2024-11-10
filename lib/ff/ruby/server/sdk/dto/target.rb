require 'set'

class Target
  attr_accessor :name, :identifier, :attributes, :is_private, :private_attributes

  # Define all parameters as keyword arguments
  def initialize(identifier:, name: nil, attributes: {}, is_private: false)
    @identifier = identifier
    @name = name || identifier
    @attributes = attributes.transform_keys(&:to_sym) || {}
    @is_private = is_private
    @private_attributes = Set.new
  end

  def is_valid
    @identifier && !@identifier.strip.empty?
  end
end

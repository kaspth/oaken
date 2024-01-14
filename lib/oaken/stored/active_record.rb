class Oaken::Stored::ActiveRecord < Struct.new(:type, :key)
  def initialize(type, key = nil)
    super(type, key || Oaken.inflector.tableize(type.name))
    @attributes = {}
  end
  delegate :transaction, to: :type # For multi-db setups to help open a transaction on secondary connections.
  delegate :find, :insert_all, :pluck, to: :type

  def defaults(**attributes)
    @attributes = @attributes.merge(attributes)
    @attributes
  end

  def create(label = nil, **attributes)
    attributes = @attributes.merge(attributes)
    attributes.transform_values! { _1.respond_to?(:call) ? _1.call : _1 }

    record = type.create!(**attributes)
    define_label_method label, record.id if label
    record
  end

  def insert(label = nil, **attributes)
    attributes = @attributes.merge(attributes)
    attributes.transform_values! { _1.respond_to?(:call) ? _1.call : _1 }

    type.new(attributes).validate!
    record = type.new(id: type.insert(attributes, returning: :id).rows.first.first)
    define_label_method label, record.id if label
    record
  end

  private def define_label_method(name, id)
    location = caller_locations(2, 1).first
    class_eval "def #{name} = find(#{id})", location.path, location.lineno
  end
end

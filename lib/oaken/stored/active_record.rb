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

  def create(reader = nil, **attributes)
    location = caller_locations(1, 1).first

    attributes = @attributes.merge(attributes)
    attributes.transform_values! { _1.respond_to?(:call) ? _1.call : _1 }

    type.create!(**attributes).tap do |record|
      define_reader reader, record.id, location if reader
    end
  end

  def insert(reader = nil, **attributes)
    location = caller_locations(1, 1).first

    attributes = @attributes.merge(attributes)
    attributes.transform_values! { _1.respond_to?(:call) ? _1.call : _1 }

    type.new(attributes).validate!
    type.insert(attributes).tap do
      define_reader reader, type.where(attributes).pick(:id), location if reader
    end
  end

  private def define_reader(name, id, location)
    class_eval "def #{name} = find(#{id})", location.path, location.lineno
  end
end

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
    lineno = caller_locations(1, 1).first.lineno

    attributes = @attributes.merge(attributes)
    attributes.transform_values! { _1.respond_to?(:call) ? _1.call : _1 }

    type.create!(**attributes).tap do |record|
      define_reader reader, record.id, lineno if reader
    end
  end

  def insert(reader = nil, **attributes)
    lineno = caller_locations(1, 1).first.lineno

    attributes = @attributes.merge(attributes)
    attributes.transform_values! { _1.respond_to?(:call) ? _1.call : _1 }

    type.new(attributes).validate!
    type.insert(attributes).tap do
      define_reader reader, type.where(attributes).pick(:id), lineno if reader
    end
  end

  def define_reader(...)
    Oaken::Seeds.entry.define_reader(self, ...)
  end
end

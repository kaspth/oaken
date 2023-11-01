class Oaken::Stored::ActiveRecord < Struct.new(:type, :key)
  def initialize(type, key = nil)
    super(type, key || Oaken.inflector.tableize(type.name))
  end
  delegate :transaction, to: :type # For multi-db setups to help open a transaction on secondary connections.
  delegate :find, :insert_all, to: :type

  def create(reader = nil, **attributes)
    lineno = caller_locations(1, 1).first.lineno

    type.create!(**attributes).tap do |record|
      define_reader reader, record.id, lineno if reader
    end
  end

  def insert(reader = nil, **attributes)
    lineno = caller_locations(1, 1).first.lineno

    type.new(attributes).validate!
    type.insert(attributes).tap do
      define_reader reader, type.where(attributes).pick(:id), lineno if reader
    end
  end

  def define_reader(...)
    Oaken::Seeds.entry.define_reader(self, ...)
  end
end

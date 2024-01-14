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
    label label => record if label
    record
  end

  def upsert(label = nil, unique_by: nil, **attributes)
    attributes = @attributes.merge(attributes)
    attributes.transform_values! { _1.respond_to?(:call) ? _1.call : _1 }

    type.new(attributes).validate!
    record = type.new(id: type.upsert(attributes, unique_by: unique_by, returning: :id).rows.first.first)
    label label => record if label
    record
  end

  def label(**labels)
    # TODO: Fix hardcoding of db/seeds instead of using Oaken.lookup_paths
    location = caller_locations(1, 6).find { _1.path.match? /db\/seeds\// }

    labels.each do |label, record|
      class_eval "def #{label} = find(#{record.id})", location.path, location.lineno
    end
  end
end

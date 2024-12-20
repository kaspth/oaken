class Oaken::Stored::ActiveRecord
  def initialize(type)
    @type, @key = type, type.table_name
    @attributes = Oaken::Seeds.defaults_for(*type.column_names)
  end
  attr_reader :type, :key
  delegate :transaction, to: :type # For multi-db setups to help open a transaction on secondary connections.
  delegate :find, :insert_all, :pluck, to: :type

  def defaults(**attributes)
    @attributes = @attributes.merge(attributes)
    @attributes
  end

  def create(label = nil, unique_by: nil, **attributes)
    attributes = @attributes.merge(attributes)
    attributes.transform_values! { _1.respond_to?(:call) ? _1.call : _1 }

    finders  = attributes.slice(*unique_by)
    record   = type.find_by(finders)&.tap { _1.update!(**attributes) } if finders.any?
    record ||= type.create!(**attributes)

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

  # Expose a record instance that's setup outside of using `create`/`upsert`. Like this:
  #
  #   users.label someone: User.create!(name: "Someone")
  #   users.label someone: FactoryBot.create(:user, name: "Someone")
  #
  # Now `users.someone` returns the record instance.
  #
  # Ruby's Hash argument forwarding also works:
  #
  #   someone = users.create(name: "Someone")
  #   someone_else = users.create(name: "Someone Else")
  #   users.label someone:, someone_else:
  #
  # Note: `users.method(:someone).source_location` also points back to the file and line of the `label` call.
  def label(**labels)
    labels.transform_values(&:id).each { _label _1, _2 }
  end

  private def _label(name, id)
    raise ArgumentError, "you can only define labelled records outside of tests" \
      unless location = Oaken::Loader.definition_location

    class_eval "def #{name} = find(#{id.inspect})", location.path, location.lineno
  end
end

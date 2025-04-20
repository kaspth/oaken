class Oaken::Stored::ActiveRecord
  def initialize(loader, type)
    @loader, @type = loader, type
    @attributes = loader.defaults_for(*type.column_names)
  end
  attr_reader :type
  delegate :transaction, to: :type # For multi-db setups to help open a transaction on secondary connections.
  delegate :find, :insert_all, :pluck, to: :type

  # Create a record in the database with the passed `attributes`.
  def create(label = nil, unique_by: nil, **attributes)
    attributes = attributes_for(**attributes)

    finders  = attributes.slice(*unique_by)
    record   = type.find_by(finders)&.tap { _1.update!(**attributes) } if finders.any?
    record ||= type.create!(**attributes)

    _label label, record.id if label
    record
  end

  # Upsert a record in the database with the passed `attributes`.
  def upsert(label = nil, unique_by: nil, **attributes)
    attributes = attributes_for(**attributes)

    type.new(attributes).validate!
    record = type.new(id: type.upsert(attributes, unique_by: unique_by, returning: :id).rows.first.first)
    _label label, record.id if label
    record
  end

  # Build attributes used for `create`/`upsert`, applying loader and per-type `defaults`.
  #
  #   loader.defaults name: -> { "Global" }, email_address: -> { … }
  #   users.defaults name: -> { Faker::Name.name } # This `name` takes precedence on users.
  #
  #   users.attributes_for(email_address: "user@example.com") # => { name: "Some Faker Name", email_address: "user@example.com" }
  def attributes_for(**attributes)
    @attributes.merge(attributes).transform_values! { _1.respond_to?(:call) ? _1.call : _1 }
  end

  # Set defaults for all types:
  #
  #   loader.defaults name: -> { "Global" }, email_address: -> { … }
  #
  # These defaults are used and evaluated in `create`/`upsert`/`attributes_for`, but you can override on a per-type basis:
  #
  #   users.defaults name: -> { Faker::Name.name } # This `name` takes precedence on `users`.
  #   users.create # => Uses the users' default `name` and the loader `email_address`
  def defaults(**attributes) = @attributes = @attributes.merge(attributes)

  # Expose a record instance that's setup outside of using `create`/`upsert`. Like this:
  #
  #   users.label someone: User.create!(name: "Someone")
  #   users.label someone: FactoryBot.create(:user, name: "Someone")
  #
  # Now `users.someone` returns the record instance.
  #
  # Ruby's Hash argument forwarding also works:
  #
  #   someone, someone_else = users.create(name: "Someone"), users.create(name: "Someone Else")
  #   users.label someone:, someone_else:
  #
  # Note: `users.method(:someone).source_location` also points back to the file and line of the `label` call.
  def label(**labels) = labels.each { |label, record| _label label, record.id }

  private def _label(name, id)
    location = @loader.definition_location or
      raise ArgumentError, "you can only define labelled records outside of tests"

    class_eval "def #{name} = find(#{id.inspect})", location.path, location.lineno
  end
end

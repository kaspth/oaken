class Oaken::Stored::ActiveRecord
  attr_reader :loader, :type
  delegate :context, to: :loader

  delegate :transaction, to: :type # For multi-db setups to help open a transaction on secondary connections.
  delegate :find, :insert_all, :pluck, to: :type

  def initialize(loader, type)
    @loader, @type = loader, type
    @original_label_target = singleton_class # Capture original self so labels made during `with` calls, retarget original.
    @attributes = loader.defaults_for(*type.column_names)
  end

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

  # `with` allows you to group similar `create`/`upsert` calls & apply scoped defaults.
  #
  # ### `with` during setup
  #
  # During seeding setup, use `with` in the block form to group `create`/`upsert` calls, typically by an association you want to highlight.
  #
  # In this example, we're grouping menu items by their menu. We could write out each menu item `create` one by one and pass the menus explicitly just fine.
  #
  # However, grouping by the menu gets us an extra level of indentation to help reveal our intent.
  #
  #   menu_items.with menu: menus.basic do
  #     it.create :plain_donut, name: "Plain Donut"
  #     it.create name: "Another Basic Donut"
  #     # More `create` calls, which automatically go on the basic menu.
  #   end
  #
  #   menu_items.with menu: menus.premium do
  #     it.create :premium_donut, name: "Premium Donut"
  #     # Other premium menu items.
  #   end
  #
  # ### `with` in tests
  #
  # In tests `with` is also useful in the non-block form to apply more explicit scoped defaults used throughout the tests:
  #
  #   setup do
  #     @menu_items = menu_items.with menu: accounts.kaspers_donuts.menus.first, description: "Indulgent & delicious."
  #   end
  #
  #   test "something" do
  #     @menu_items.create # The menu item is created with the defaults above.
  #     @menu_items.create menu: menus.premium # You can still override defaults like usual.
  #   end
  #
  # ### How `with` scoping works
  #
  # To make this easier to understand we'll use a general `menu_items` object and then a scoped `basic_items = menu_items.with menu: menus.basic` object.
  #
  # - Labels: go to the general object, `basic_items.create :plain_donut` will be reachable via `menu_items.plain_donut`.
  # - Defaults: only stay on the `with` object, so `menu_items.create` won't set `menu: menus.basic`, but `basic_items.create` will.
  # - Helper methods: any helper methods defined on `menu_items` can be called on `basic_items`. We recommend only defining helper methods on the general `menu_items` object.
  def with(**defaults)
    clone.tap do
      _1.defaults(**defaults) unless defaults.empty?
      yield _1 if block_given?
    end
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

  # `proxy` lets you wrap and delegate scopes from the underlying record.
  #
  # So if you have this Active Record:
  #
  #   class User < ApplicationRecord
  #     enum :role, %w[admin mod plain].index_by(&:itself)
  #     scope :cool, -> { where(cool: true) }
  #   end
  #
  # You can then proxy the scopes and use them like this:
  #
  #   users.proxy :admin, :mod, :plain
  #   users.proxy :cool
  #
  #   users.create       # Has `role: "plain"`, assuming it's the default role.
  #   users.admin.create # Has `role: "admin"`
  #   users.mod.create   # Has `role: "mod"`
  #   users.cool.create  # Has `cool: true`
  #
  #   # Chaining also works:
  #   users.cool.admin.create # Has `cool: true, role: "admin"`
  def proxy(*names) = names.each do |name|
    define_singleton_method(name) { clone.rebind(type.public_send(name)) }
  end

  protected def rebind(type)
    @type = type
    self
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
  #   someone, someone_else = users.create(name: "Someone"), users.create(name: "Someone Else")
  #   users.label someone:, someone_else:
  #
  # Note: `users.method(:someone).source_location` also points back to the file and line of the `label` call.
  def label(**labels) = labels.each { |label, record| _label label, record.id }

  private def _label(name, id)
    location = @loader.definition_location or
      raise ArgumentError, "you can only define labelled records outside of tests"

    @original_label_target.class_eval "def #{name} = find(#{id.inspect})", location.path, location.lineno
  end
end

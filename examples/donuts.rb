require "bundler/inline"; gemfile do
  source "https://rubygems.org"

  gem "debug"

  gem "activerecord", require: "active_record"
  gem "sqlite3"
  gem "bcrypt"

  gem "oaken", path: ".."
end

require "active_support/testing/autorun"

ActiveRecord::Base.logger = Logger.new(STDOUT)

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  establish_connection adapter: "sqlite3", database: ":memory:"
  singleton_class.delegate :create_table, to: :lease_connection
end

class Account < ApplicationRecord
  create_table :accounts do |t|
    t.string :name, null: false
    t.timestamps
  end
end

class User < ApplicationRecord
  create_table :users do |t|
    t.string :name, null: false
    t.string :email_address, null: false
    t.string :password_digest, null: false
    t.string :role, default: "plain", null: false
    t.timestamps

    t.index :email_address, unique: true
  end

  has_secure_password

  enum :role, %w[admin mod plain].index_by(&:itself)

  has_many :administratorships
  has_many :accounts, through: :administratorships
end

class Administratorship < ApplicationRecord
  create_table :administratorships do |t|
    t.references :account, null: false, index: true
    t.references :user, null: false, index: true
    t.timestamps
  end

  belongs_to :account
  belongs_to :user
end

class Menu < ApplicationRecord
  create_table :menus do |t|
    t.references :account, null: false, index: true
    t.timestamps
  end

  belongs_to :account
end

class Menu::Item < ApplicationRecord
  create_table :menu_items do |t|
    t.references :menu, null: false, index: true
    t.string :name, null: false
    t.integer :price_cents, null: false
    t.timestamps
  end

  belongs_to :menu
end

# We have to override this for the single file script here, but you don't need this in apps.
class Oaken::Loader
  def definition_location = caller_locations(3, 1)&.first
end

# Simulate db/seeds.rb
# Oaken.seed :accounts # Will load `db/seeds/{,<Rails.env>/}accounts**/*.rb`

# Simulate db/seeds/setup.rb
# In Rails apps `Oaken.context.class_eval` is automatic.
Oaken.context.class_eval do
  # Set general defaults across models. Only the models with these columns will use this default, e.g. `menu_items#price_cents`.
  loader.defaults price_cents: 10_00

  # Use the decorative `section` method to carve up files.
  section users do
    # password/password_confirmation are virtual columns generated via `has_secure_password`
    users.defaults password: "password123456", password_confirmation: "password123456"

    # Expose the `enum :role` scopes, so `users.admin.create` will set `role: "admin"`.
    users.proxy :admin, :mod, :plain

    # This defined helper method uses Ruby's built-in `singleton_methods`. Not to be conflated with `include Singleton`.
    # So we're overriding the built-in create method to mark users as unique by their `email_address`.
    def users.create(label = nil, unique_by: :email_address, **) = super
  end
end

# Simulate an db/seeds/accounts/kaspers_donuts.rb file.
# In Rails apps `Oaken.context.class_eval` is automatic.
Oaken.context.class_eval do
  account = accounts.create :kaspers_donuts, name: "Kasper's Donuts"

  users.with accounts: [account] do
    kasper   = it.admin.create :kasper, name: "Kasper",   email_address: "kasper@example.com"
    coworker = it.mod.create :coworker, name: "Coworker", email_address: "coworker@example.com"
  end

  menu = menus.create(:basic, account:)
  plain_donut     = menu_items.create menu:, name: "Plain" # Gets `price_cents: 10_00` from `loader.defaults`
  sprinkled_donut = menu_items.create menu:, name: "Sprinkled", price_cents: 20_00
end

class OakenTest < ActiveSupport::TestCase
  include Oaken.context # In real Rails apps you should include `Oaken.test_setup` instead.

  setup do
    @user = users.kasper
    @menu_items = menu_items.with menu: menus.basic, name: "High Price", price_cents: 20_00
  end

  test "access seeded records" do
    assert_equal "Kasper", @user.name

    @menu_items.create.tap do |item|
      assert_equal "High Price", item.name
      assert_equal 20_00, item.price_cents
      assert_equal menus.basic, item.menu
    end
  end
end

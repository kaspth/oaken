# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "oaken"

require "active_record"
require "minitest/autorun"

module Rails
  def self.root() = __dir__ # Needed for the sqlite3 tasks.
end

ActiveRecord::Base.configurations = {
  sqlite:   { adapter: "sqlite3",    pool: 5, database: "tmp/oaken_test.sqlite3" },
  mysql:    { adapter: "mysql2",     pool: 5, encoding: "utf8mb4", database: "oaken_test", username: "root", host: "localhost" },
  postgres: { adapter: "postgresql", pool: 5, encoding: "unicode", database: "oaken_test" }
}

adapter = :sqlite

database = ActiveRecord::Base.configurations.resolve(adapter).then do |config|
  case adapter
  when :sqlite   then ActiveRecord::Tasks::SQLiteDatabaseTasks.new(config)
  when :mysql    then ActiveRecord::Tasks::MySQLDatabaseTasks.new(config)
  when :postgres then ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(config)
  end
end

begin
  database.create
rescue ActiveRecord::DatabaseAlreadyExists
end

Minitest.after_run { database.drop }

ActiveRecord::Base.establish_connection(adapter)
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :accounts, force: true do |t|
    t.string :name, null: false
    t.timestamps
  end

  create_table :memberships, force: true do |t|
    t.integer :account_id, null: false
    t.integer :user_id,    null: false
    t.timestamps
  end

  create_table :users, force: true do |t|
    t.string :name, null: false
    t.timestamps
  end

  create_table :plans, force: true do |t|
    t.string :title, null: false
    t.integer :price_cents, null: false
    t.timestamps
  end
end

class Account < ActiveRecord::Base
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships, dependent: :destroy
end

class Membership < ActiveRecord::Base
  belongs_to :account
  belongs_to :user
end

class User < ActiveRecord::Base
  has_many :memberships
  has_many :accounts, through: :memberships
end

class Plan < ActiveRecord::Base
  after_save { raise "after_save" }
end

class YamlRecord < ActiveRecord::Base
  belongs_to :account
end

require "active_record/fixtures"

Oaken::Seeds.records.preregister ActiveRecord::Base.connection.tables.grep_v(/^ar_/)
Oaken::Seeds.load_from "test/seeds"

class Oaken::Test < ActiveSupport::TestCase
  include ActiveRecord::TestFixtures
  self.fixture_path = "test/fixtures"
  self.use_transactional_tests = true
  fixtures :all

  include Oaken::Seeds
end

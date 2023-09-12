# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "rails"
require "rails/test_help"

require "active_record"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "oaken"

ActiveRecord::Base.configurations = {
  sqlite:   { adapter: "sqlite3",    pool: 5, database: "../tmp/oaken_test.sqlite3" },
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

ActiveRecord::Base.establish_connection(adapter)
ActiveRecord::Base.logger = Logger.new(STDOUT)

begin
  ActiveRecord::Schema.define do
    create_table :accounts do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :memberships do |t|
      t.integer :account_id, null: false
      t.integer :user_id,    null: false
      t.timestamps
    end

    create_table :users do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :plans do |t|
      t.string :title, null: false
      t.integer :price_cents, null: false
      t.timestamps
    end
  end
rescue ActiveRecord::StatementInvalid
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

Oaken::Seeds.preregister ActiveRecord::Base.connection.tables.grep_v(/^ar_/)
Oaken::Seeds.load_from "test/seeds"

class Oaken::Test < ActiveSupport::TestCase
  include Oaken::Seeds

  # Override Minitest::Test#run to wrap each test in a transaction.
  def run
    result = nil
    ActiveRecord::Base.transaction(requires_new: true) do
      result = super
      raise ActiveRecord::Rollback
    end
    result
  end
end

# # If we keep it to a DSL what do we actually need to be able to skip the file?

# # Create a statement for each line
# # Same as Reference?
# class Oaken::Seeds::Statement
# end

# # Create a result for each file
# class Oaken::Seeds::Result
#   # filename + checksum
#   has_many :references
# end

# # users.create :kasper, name: "Kasper"
# # create an Oaken::Seeds::Reference.create!(collection_name: "users", name: "kasper", id: )
# class Oaken::Seeds::Reference < ActiveRecord::Base
#   def define
#     scope.define_method(name) { find record_id }
#   end

#   def scope
#     Oaken::Seeds.public_send(collection_name)
#   end
# end

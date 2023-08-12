# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "oaken"

require "active_record"
require "minitest/autorun"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
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

  create_table :comments, force: true do |t|
    t.string :title, null: false
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

class Comment < ActiveRecord::Base
end

Oaken::Data.records.preregister ActiveRecord::Base.connection.tables.grep_v(/^ar_/)
Oaken::Data.load_from "test/seeds"

class Oaken::Test < ActiveSupport::TestCase
  include ActiveRecord::TestFixtures
  self.use_transactional_tests = true

  include Oaken::Data
end

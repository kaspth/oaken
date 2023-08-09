# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "oaken"

require "active_record"
require "minitest/autorun"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name, null: false
    t.timestamps
  end

  create_table :comments, force: true do |t|
    t.string :title, null: false
    t.timestamps
  end
end

class User < ActiveRecord::Base
end

class Comment < ActiveRecord::Base
end


Oaken::Data.load_from "test/seeds"

class Oaken::Test < ActiveSupport::TestCase
  include ActiveRecord::TestFixtures
  self.use_transactional_tests = true

  include Oaken::Data
end

require "bundler/inline"; gemfile do
  source "https://rubygems.org"

  gem "debug"

  gem "activerecord", require: "active_record"
  gem "sqlite3"

  gem "oaken", "0.9.1" # TODO: Lock to the version you're using.
end

require "active_support/testing/autorun"

ActiveRecord::Base.logger = Logger.new(STDOUT)

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  establish_connection adapter: "sqlite3", database: ":memory:"
  singleton_class.delegate :create_table, to: :lease_connection
end

class User < ApplicationRecord
  create_table :users do |t|
    t.string :name, null: false
  end
end

# TODO: Put extra models/tables here as needed. Feel free to update User too.

ApplicationRecord.subclasses.each { Oaken.register _1 }

class BugTest < ActiveSupport::TestCase
  include Oaken.context

  setup do
    @user = users.create name: "Someone"
  end

  test "it fails if I try this" do
    # debugger # Uncomment or place elsewhere to use debug.rb's debugger
    assert_equal "Someone", @user.name
  end

  test "yet somehow it passes if I do this" do
  end
end

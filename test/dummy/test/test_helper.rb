ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

Oaken::Seeds.preregister ActiveRecord::Base.connection.tables.grep_v(/^ar_/)
Oaken::Seeds.load_from "db/seeds/accounts/kaspers_donuts"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  include Oaken::Seeds
end

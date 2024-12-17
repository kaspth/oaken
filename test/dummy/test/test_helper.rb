ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV["VERBOSE"] || ENV["CI"]

class ActiveSupport::TestCase
  parallelize workers: :number_of_processors, threshold: ENV.fetch("PARALLEL_TEST_THRESHOLD", 5).to_i

  include Oaken::TestSetup

  setup do
    db = ActiveRecord::Base.connection.raw_connection
    db.enable_load_extension(true)
    SqliteUlid.load db
  end if ENV["RAILS_VERSION"] == "7.1"
end

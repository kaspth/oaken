ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

ActiveRecord::Base.logger = Logger.new(STDOUT)

class ActiveSupport::TestCase
  parallelize workers: :number_of_processors, threshold: ENV.fetch("PARALLEL_TEST_THRESHOLD", 5).to_i

  include Oaken::TestSetup
end

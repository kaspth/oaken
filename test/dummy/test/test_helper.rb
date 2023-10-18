ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# ActiveRecord::Base.logger = Logger.new(STDOUT)

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize workers: :number_of_processors

  include Oaken.seeds

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

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

ActiveRecord::Base.logger = Logger.new(STDOUT)

class ActiveSupport::TestCase
  parallelize workers: :number_of_processors, threshold: 5

  prepend Oaken::TestSetup
  include Oaken.seeds
  fixtures :all
end

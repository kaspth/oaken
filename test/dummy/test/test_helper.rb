ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

ActiveRecord::Base.logger = Logger.new(STDOUT)

class ActiveSupport::TestCase
  parallelize workers: :number_of_processors, threshold: 5

  include Oaken::TestSetup
end

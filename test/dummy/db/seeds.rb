ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV["VERBOSE"] || ENV["CI"]

Oaken.seed :accounts, :data

RSpec.configure do |config|
  config.include(Oaken::Seeds)

  config.use_transactional_fixtures = true

  config.before(:suite) do
    # Mimic fixtures by truncating before inserting.
    ActiveRecord::Tasks::DatabaseTasks.truncate_all
    Oaken.load_seed
  end
end

RSpec.configure do |config|
  config.include Oaken::Seeds
  config.use_transactional_fixtures = true

  config.before :suite do
    Oaken.replant_seed
  end
end

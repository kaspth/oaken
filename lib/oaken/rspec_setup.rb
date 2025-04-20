RSpec.configure do |config|
  config.include Oaken.loader.context
  config.use_transactional_fixtures = true
  config.before(:suite) { Oaken.loader.replant_seed }
end

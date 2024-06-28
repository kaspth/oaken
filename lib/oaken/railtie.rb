module Oaken
  class Railtie < Rails::Railtie
    config.app_generators.test_unit fixture: false

    initializer "oaken.lookup_paths" do
      Oaken.lookup_paths << "db/seeds/#{Rails.env}"
    end
  end
end

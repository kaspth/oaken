module Oaken
  class Railtie < Rails::Railtie
    config.app_generators do
      _1.test_framework _1.test_framework, fixture: false
    end

    initializer "oaken.lookup_paths" do
      Oaken.lookup_paths << "db/seeds/#{Rails.env}"
    end
  end
end

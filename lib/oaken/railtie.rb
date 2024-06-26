module Oaken
  class Railtie < Rails::Railtie
    initializer "oaken.set_fixture_replacement" do
      GeneratorConfiguration.run(config)
    end

    initializer "oaken.lookup_paths" do
      Oaken.lookup_paths << "db/seeds/#{Rails.env}"
    end
  end

  class GeneratorConfiguration
    def self.run(config)
      test_framework = config.app_generators.options[:rails][:test_framework]

      config.app_generators.test_framework(
        test_framework,
        fixture: false,
        fixture_replacement: :oaken
      )
    end
  end
end
module Oaken
  class Railtie < Rails::Railtie
    initializer "oaken.lookup_paths" do
      Oaken.subpaths << Rails.env
    end
  end
end

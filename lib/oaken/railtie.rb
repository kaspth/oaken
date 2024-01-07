class Oaken::Railtie < Rails::Railtie
  initializer "oaken.lookup_paths" do
    Oaken.lookup_paths << "db/seeds/#{Rails.env}"
  end
end

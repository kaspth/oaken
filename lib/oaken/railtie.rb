class Oaken::Railtie < Rails::Railtie
  initializer "oaken.defaults" do
    Oaken.lookup_paths << "db/seeds/#{Rails.env}"
    Oaken.store_path = Oaken.store_path.join(Rails.env)
  end
end

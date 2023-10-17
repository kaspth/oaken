class Oaken::Railtie < Rails::Railtie
  initializer "oaken.defaults" do
    Oaken.store_path = Oaken.store_path.join(Rails.env)
  end
end

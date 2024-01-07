class Oaken::Railtie < Rails::Railtie
  initializer "oaken.defaults" do
    Oaken.lookup_paths << "db/seeds/#{Rails.env}"
  end

  rake_tasks do
    namespace :oaken do
      task("reset")     { Oaken.store_path.rmtree }
      task("reset:all") { Oaken.store_path.dirname.rmtree }

      task "reset:include_test" do
        # Some db: tasks in development also manipulate the test database.
        Oaken.store_path.sub("development", "test").rmtree if Rails.env.development?
      end
    end

    task "db:drop"      => ["oaken:reset", "oaken:reset:include_test"]
    task "db:purge"     => ["oaken:reset", "oaken:reset:include_test"]
    task "db:purge:all" => ["oaken:reset:all"]

    # db:seed:replant runs trunacte_all, after trial-and-error we need to hook into that and not the replant task.
    task "db:truncate_all" => "oaken:purge"
  end
end

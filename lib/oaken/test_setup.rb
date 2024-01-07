module Oaken::TestSetup
  SETUP_OAKEN = proc do
    Oaken.store_path += ActiveRecord::Base.connection.current_database
    Oaken.store_path.rmtree
    Oaken.seeds
  end

  def self.prepended(klass)
    klass.include Oaken::Seeds
    klass.parallelize_setup(&SETUP_OAKEN)
  end

  def before_setup
    unless Minitest.parallel_executor.send(:should_parallelize?)
      ActiveRecord::Tasks::DatabaseTasks.truncate_all
      SETUP_OAKEN.call
    end
    Oaken::TestSetup.remove_method :before_setup

    super
  end
end

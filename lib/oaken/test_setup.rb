module Oaken::TestSetup
  def self.prepended(klass)
    klass.include Oaken::Seeds
    klass.fixtures # Rely on fixtures to setup a shared connection pool and wrap tests in transactions.
    klass.parallelize_setup { Oaken.seeds }
  end

  def before_setup
    unless Minitest.parallel_executor.send(:should_parallelize?)
      ActiveRecord::Tasks::DatabaseTasks.truncate_all
      Oaken.seeds
    end
    Oaken::TestSetup.remove_method :before_setup

    super
  end
end

module Oaken::TestSetup
  def self.prepended(klass)
    klass.include Oaken::Seeds
    klass.fixtures # Rely on fixtures to setup a shared connection pool and wrap tests in transactions.
    klass.parallelize_setup { Oaken.seeds } # No need to truncate as parallel test databases are always empty.
  end

  # We must inject late enough to call `should_parallelize?`, but before fixtures' `before_setup`.
  #
  # So we prepend into `before_setup` and later `super` to have fixtures wrap tests in transactions.
  def before_setup
    unless Minitest.parallel_executor.send(:should_parallelize?)
      ActiveRecord::Tasks::DatabaseTasks.truncate_all # Mimic fixtures by truncating before inserting.
      Oaken.seeds
    end

    Oaken::TestSetup.remove_method :before_setup # Only run once, so remove before passing to fixtures in `super`.
    super
  end
end

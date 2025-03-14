module Oaken::TestSetup
  include Oaken::Seeds

  def self.included(klass)
    klass.fixtures # Rely on fixtures to setup a shared connection pool and wrap tests in transactions.
    klass.parallelize_setup { Oaken.load_seed } # No need to truncate as parallel test databases are always empty.
    klass.prepend BeforeSetup
  end

  module BeforeSetup
    # We must inject late enough to call `should_parallelize?`, but before fixtures' `before_setup`.
    #
    # So we prepend into `before_setup` and later `super` to have fixtures wrap tests in transactions.
    def before_setup
      # `should_parallelize?` is only defined when Rails' test `parallelize` macro has been called.
      unless Minitest.parallel_executor.then { _1.respond_to?(:should_parallelize?, true) && _1.send(:should_parallelize?) }
        ActiveRecord::Tasks::DatabaseTasks.truncate_all # Mimic fixtures by truncating before inserting.
        Oaken.load_seed
      end

      Oaken::TestSetup::BeforeSetup.remove_method :before_setup # Only run once, so remove before passing to fixtures in `super`.
      super
    end
  end
end

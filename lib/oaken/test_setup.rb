class Oaken::TestSetup < Module
  def initialize(loader)
    @loader = loader

    # We must inject late enough to call `should_parallelize?`, but before fixtures' `before_setup`.
    #
    # So we prepend into `before_setup` and later `super` to have fixtures wrap tests in transactions.
    instance = self
    define_method :before_setup do
      # `should_parallelize?` is only defined when Rails' test `parallelize` macro has been called.
      loader.replant_seed unless Minitest.parallel_executor.then { _1.respond_to?(:should_parallelize?, true) && _1.send(:should_parallelize?) }

      instance.remove_method :before_setup # Only run once, so remove before passing to fixtures in `super`.
      super()
    end
  end

  def included(klass)
    klass.fixtures # Rely on fixtures to setup a shared connection pool and wrap tests in transactions.
    klass.include @loader.context
    klass.parallelize_setup { @loader.load_seed } # No need to truncate as parallel test databases are always empty.
  end
end

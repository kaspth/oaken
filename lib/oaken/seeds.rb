module Oaken::Seeds
  extend self

  def self.respond_to_missing?(name, ...)
    Oaken.inflector.classify(name).safe_constantize || super
  end

  def self.method_missing(meth, ...)
    name = meth.to_s
    if type = Oaken.inflector.classify(name).safe_constantize
      register type, name
      public_send(name, ...)
    else
      super
    end
  end

  def self.register(type, key = nil)
    stored = provider.new(type, key) and define_method(stored.key) { stored }
  end
  def self.provider = Oaken::Stored::ActiveRecord

  class << self
    # Set up a general seed rule or perform a one-off seed for a test file.
    #
    # You can set up a general seed rule in `db/seeds.rb` like this:
    #
    #   Oaken.prepare do
    #     seed :accounts # Seeds from `db/seeds/accounts/**/*.rb` and `db/seeds/<Rails.env>/accounts/**/*.rb`
    #   end
    #
    # Then if you need a test specific scenario, we recommend putting them in `db/seeds/test/cases`.
    #
    # Say you have `db/seeds/test/cases/pagination.rb`, you can load it like this:
    #
    #   # test/integration/pagination_test.rb
    #   class PaginationTest < ActionDispatch::IntegrationTest
    #     setup { seed "cases/pagination" }
    #   end
    def seed(*directories)
      Oaken.lookup_paths.product(directories).each do |path, directory|
        load_from Pathname(path).join(directory.to_s)
      end
    end

    private def load_from(path)
      @loader = Oaken::Loader.new path
      @loader.load_onto self
    ensure
      @loader = nil
    end
    def entry = @loader.entry
  end

  # Call `seed` in tests to load individual case files:
  #
  #   class PaginationTest < ActionDispatch::IntegrationTest
  #     setup do
  #       seed "cases/pagination" # Loads `db/seeds/{,test}/cases/pagination{,**/*}.rb`
  #     end
  #   end
  delegate :seed, to: Oaken::Seeds
end

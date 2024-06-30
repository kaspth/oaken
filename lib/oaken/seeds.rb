module Oaken::Seeds
  extend self

  # Allow assigning defaults across different types.
  def self.defaults(**defaults) = attributes.merge!(**defaults)
  def self.defaults_for(*keys) = attributes.slice(*keys)
  def self.attributes = @attributes ||= {}.with_indifferent_access

  # Oaken's main auto-registering logic.
  #
  # So when you first call e.g. `accounts.create`, we'll hit `method_missing` here
  # and automatically call `register Account`.
  #
  # We'll also match partial and full nested namespaces like in this order:
  #
  #   accounts => Account
  #   account_jobs => AccountJob | Account::Job
  #   account_job_tasks => AccountJobTask | Account::JobTask | Account::Job::Task
  #
  # If you have classes that don't follow this naming convention, you must call `register` manually.
  def self.method_missing(meth, ...)
    name = meth.to_s.classify
    name = name.sub!(/(?<=[a-z])(?=[A-Z])/, "::") until name.nil? or type = name.safe_constantize

    if type
      register type
      public_send(meth, ...)
    else
      super
    end
  end
  def self.respond_to_missing?(name, ...) = name.to_s.classify.safe_constantize || super

  # Register a model class to be accessible as an instance method via `include Oaken::Seeds`.
  # Note: Oaken's auto-register via `method_missing` means it's less likely you need to call this manually.
  #
  #   register Account, Account::Job, Account::Job::Task
  #
  # Oaken uses the `table_name` of the passed classes for the method names, e.g. here they'd be
  # `accounts`, `account_jobs`, and `account_job_tasks`, respectively.
  def self.register(*types)
    types.each do |type|
      stored = provider.new(type) and define_method(stored.key) { stored }
    end
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

    # `section` is purely for decorative purposes to carve up `Oaken.prepare` and seed files.
    #
    #   Oaken.prepare do
    #     section :roots # Just the very few top-level models like Accounts and Users.
    #     users.defaults email_address: -> { Faker::Internet.email }, webauthn_id: -> { SecureRandom.hex }
    #
    #     section :stems # Models building on the roots.
    #
    #     section :leafs # Remaining models, bulk of them, hanging off root and stem models.
    #
    #     section do
    #       seed :accounts, :data
    #     end
    #   end
    #
    # Since `section` is defined as `def section(*, **) = yield if block_given?`, you can use
    # all of Ruby's method signature flexibility to help communicate structure better.
    #
    # Use positional and keyword arguments, or use blocks to indent them, or combine them all.
    def section(*, **)
      yield if block_given?
    end
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

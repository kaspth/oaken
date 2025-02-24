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
  # We'll also match partial and full nested namespaces:
  #
  #   accounts => Account
  #   account_jobs => Account::Job | AccountJob
  #   account_job_tasks => Account::JobTask | Account::Job::Task | AccountJob::Task | AccountJobTask
  #
  # If you have classes that don't follow these naming conventions, you must call `register` manually.
  def self.method_missing(meth, ...)
    if type = Oaken::Type.for(meth.to_s).locate
      register type
      public_send(meth, ...)
    else
      super
    end
  end
  def self.respond_to_missing?(name, ...) = Oaken::Type.for(name.to_s).locate || super

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
    def seed(*identifiers)
      Oaken::Loader.from(identifiers).load_onto self
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

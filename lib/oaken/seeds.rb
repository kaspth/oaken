module Oaken::Seeds
  extend self

  def self.loader = Oaken.loader
  singleton_class.delegate :seed, to: :loader

  # Call `seed` in tests to load individual case files:
  #
  #   class PaginationTest < ActionDispatch::IntegrationTest
  #     setup do
  #       seed "cases/pagination" # Loads `db/seeds/{,test}/cases/pagination{,**/*}.rb`
  #     end
  #   end
  delegate :seed, to: self

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
    if type = loader.locate(meth)
      register type, as: meth
      public_send(meth, ...)
    else
      super
    end
  end
  def self.respond_to_missing?(meth, ...) = loader.locate(meth) || super

  # Register a model class to be accessible as an instance method via `include Oaken::Seeds`.
  # Note: Oaken's auto-register via `method_missing` means it's less likely you need to call this manually.
  #
  #   register Account, Account::Job, Account::Job::Task
  #
  # Oaken uses `name.tableize.tr("/", "_")` on the passed classes for the method names, so they're
  # `accounts`, `account_jobs`, and `account_job_tasks`, respectively.
  #
  # You can also pass an explicit `as:` option, if you'd like:
  #
  #   register User, as: :something_else
  def self.register(*types, as: nil)
    types.each do |type|
      stored = loader.provided(type) and define_method(as || type.name.tableize.tr("/", "_")) { stored }
    end
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
  # Since `section` is defined as `def section(*, **) = block_given? && yield`, you can use
  # all of Ruby's method signature flexibility to help communicate structure better.
  #
  # Use positional and keyword arguments, or use blocks to indent them, or combine them all.
  def self.section(*, **) = block_given? && yield
end

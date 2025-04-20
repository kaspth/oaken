module Oaken::Seeds
  def self.loader = Oaken.loader
  singleton_class.delegate :seed, :register, to: :loader
  delegate :seed, to: self

  extend self

  # Oaken's auto-registering logic.
  #
  # So when you first call e.g. `accounts.create`, we'll hit `method_missing` here
  # and automatically call `register Account, as: :accounts`.
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

  # Purely for decorative purposes to carve up seed files.
  #
  # `section` is defined as `def section(*, **) = block_given? && yield`, so you can use
  # all of Ruby's method signature flexibility to help communicate structure better.
  #
  # Use positional & keyword arguments, blocks at multiple levels, or a combination.
  #
  #   section :basic
  #   users.create name: "Someone"
  #
  #   section :menus, quicksale: true
  #
  #   section do
  #     # Leave name implicit and carve up visually with the indentation.
  #     section something: :nested
  #
  #     section :another_level do
  #       # We can keep going, but maybe we shouldn't.
  #     end
  #   end
  def self.section(*, **) = block_given? && yield
end

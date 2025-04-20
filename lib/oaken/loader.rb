# frozen_string_literal: true

class Oaken::Loader
  class NoSeedsFoundError < ArgumentError; end

  autoload :Type, "oaken/loader/type"

  attr_reader :lookup_paths, :locator, :provider, :context
  delegate :locate, to: :locator

  def initialize(lookup_paths: nil, locator: Type, provider: Oaken::Stored::ActiveRecord, context: Oaken::Seeds)
    @setup = nil
    @lookup_paths, @locator, @provider, @context = Array(lookup_paths).dup, locator, provider, context
    @defaults = {}.with_indifferent_access
  end

  # Instantiate a new loader with all its attributes and any specified `overrides`. See #new for defaults.
  #
  #   Oaken.loader.with(root: "test/fixtures") # `root` returns "test/fixtures" here
  def with(**overrides)
    self.class.new(lookup_paths:, locator:, provider:, context:, **overrides)
  end

  # Allow assigning defaults across types.
  def defaults(**defaults) = @defaults.merge!(**defaults)
  def defaults_for(*keys)  = @defaults.slice(*keys)

  def test_setup
    Oaken::TestSetup.new self
  end

  # Register a model class via `Oaken.loader.context`.
  # Note: Oaken's auto-register means you don't need to call `register` often yourself.
  #
  #   register Account
  #   register Account::Job
  #   register Account::Job::Task
  #
  # Oaken uses `name.tableize.tr("/", "_")` for the method names, so they're
  # `accounts`, `account_jobs`, and `account_job_tasks`, respectively.
  #
  # You can also pass an explicit `as:` option:
  #
  #   register User, as: :something_else
  def register(type, as: nil)
    stored = provider.new(self, type)
    context.define_method(as || type.name.tableize.tr("/", "_")) { stored }
  end

  # Mirrors `bin/rails db:seed:replant`.
  def replant_seed
    ActiveRecord::Tasks::DatabaseTasks.truncate_all
    load_seed
  end

  # Mirrors `bin/rails db:seed`.
  def load_seed
    Rails.application.load_seed
  end

  # Set up a general seed rule or perform a one-off seed for a test file.
  #
  # You can set up a general seed rule in `db/seeds.rb` like this:
  #
  #   Oaken.seed :accounts # Seeds from `db/seeds/accounts{,/**/*}.rb` and `db/seeds/<Rails.env>/accounts{,/**/*}.rb`
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
    setup

    identifiers.flat_map { glob! _1 }.each { load_one _1 }
    self
  end

  def glob(identifier)
    Pathname.glob lookup_paths.map { File.join _1, "#{identifier}{,/**/*}.rb" }
  end

  def definition_location
    # The first line referencing LABEL happens to be the line in the seed file.
    caller_locations(3, 6).find { _1.base_label == LABEL }
  end

  private
    def setup = @setup ||= glob(:setup).each { load_one _1 }

    def glob!(identifier)
      glob(identifier).then.find(&:any?) or raise NoSeedsFoundError, "found no seed files for #{identifier.inspect}"
    end

    def load_one(path)
      context.class_eval path.read, path.to_s
    end
    LABEL = instance_method(:load_one).name.to_s
end

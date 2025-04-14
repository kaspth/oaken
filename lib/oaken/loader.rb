# frozen_string_literal: true

class Oaken::Loader
  class NoSeedsFoundError < ArgumentError; end

  autoload :Type, "oaken/loader/type"

  def initialize(root:, subpaths: nil, locator: Type, provider: Oaken::Stored::ActiveRecord, context: Oaken::Seeds)
    @pathset, @locator, @provider, @context = Pathset.new(root:, subpaths:), locator, provider, context
    @defaults = {}.with_indifferent_access
  end
  attr_reader :pathset, :locator, :provider, :context
  delegate :locate, to: :locator
  delegate :root, :root=, :subpaths, :subpaths=, to: :pathset

  def with(**options)
    self.class.new(root:, subpaths:, locator:, provider:, context:, **options)
  end

  # Allow assigning defaults across different types.
  def defaults(**defaults) = @defaults.merge!(**defaults)
  def defaults_for(*keys)  = @defaults.slice(*keys)

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
    identifiers.flat_map { glob! _1 }.each { load_one _1 }
    self
  end

  def test_setup
    Oaken::TestSetup.new self
  end

  def provided(type)
    provider.new(self, type)
  end

  def replant_seed
    truncate_all
    load_seed
  end
  def truncate_all = ActiveRecord::Tasks::DatabaseTasks.truncate_all
  def load_seed = Rails.application.load_seed

  def definition_location
    # Trickery abounds! Due to Ruby's `caller_locations` + our `load_one`'s `class_eval` above
    # we can use this format to detect the location in the seed file where the call came from.
    caller_locations(2, 8).find { _1.label == LABEL }
  end

  private
    def glob!(identifier)
      pathset.glob(identifier).then.find(&:any?) or
        raise NoSeedsFoundError, "found no seed files for #{identifier.inspect}"
    end

    def load_one(path)
      context.class_eval path.read, path.to_s
    end
    LABEL = instance_method(:load_one).name.to_s

  class Pathset
    attr_reader :root, :subpaths
    define_method(:root=) { @root = Pathname(_1) }
    define_method(:subpaths=) { @subpaths = [".", *_1].uniq }

    def initialize(root:, subpaths:)
      self.root, self.subpaths = root, subpaths
    end

    def glob(identifier)
      Pathname.glob subpaths.map { root.join _1, "#{identifier}{,/**/*}.rb" }
    end
  end
end

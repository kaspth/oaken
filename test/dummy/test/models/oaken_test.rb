require "test_helper"

class OakenTest < ActiveSupport::TestCase
  test "version number" do
    refute_nil ::Oaken::VERSION
  end

  test "accessing fixture" do
    assert_equal "Kasper", users.kasper.name
    assert_equal "Coworker", users.coworker.name

    assert_equal [accounts.kaspers_donuts], users.kasper.accounts
    assert_equal [accounts.kaspers_donuts], users.coworker.accounts
    assert_equal [users.kasper, users.coworker], accounts.kaspers_donuts.users
  end

  test "accessing fixture from test env" do
    assert plans.test_premium
  end

  test "accessing fixture defined directly from label" do
    assert menus.basic
  end

  test "accessing fixture defined directly from label with composite primary keys" do
    assert administratorships.kasper_administratorship
  end

  test "auto-registering with full namespaces" do
    assert_respond_to self, :menu_items
    assert_respond_to self, :menu_item_details

    menu_item_details.plain.tap do |detail|
      assert_equal "Plain", detail.menu_item.name
      assert_equal "Plain, but mighty.", detail.description
      assert_kind_of Menu::Item::Detail, detail
    end
  end

  test "auto-registering with partial namespaces" do
    Menu::HiddenDiscount = Class.new { def self.column_names = [] }
    assert_kind_of Oaken::Stored::ActiveRecord, Oaken::Seeds.menu_hidden_discounts

    Menu::SuperSecret = Module.new
    Menu::SuperSecret::Discount = Class.new { def self.column_names = [] }
    assert_kind_of Oaken::Stored::ActiveRecord, Oaken::Seeds.menu_super_secret_discounts
  end

  test "registering with custom alias" do
    Oaken::Seeds.register User, as: :aliased_users
    assert_kind_of Oaken::Stored::ActiveRecord, aliased_users
    assert_kind_of Oaken::Stored::ActiveRecord, Oaken::Seeds.aliased_users
  end

  test "global default attributes" do
    plan = plans.upsert price_cents: 10_00

    assert_equal "Global Default Title", plan.reload.title
  end

  test "per-type default attributes" do
    names = users.pluck(:name)

    (1..10).each do
      assert_includes names, "Customer #{_1}"
    end
  end

  test """attributes_for:
    - uses global defaults with procs
    - allows overriding global defaults
  """ do
    users.attributes_for(email_address: "user@example.com").tap do |attributes|
      assert_match /Customer \d+/, attributes[:name]
      assert_equal "user@example.com", attributes[:email_address]
    end

    plans.attributes_for(price_cents: 10_00).tap do |attributes|
      assert_equal "Global Default Title", attributes[:title]
      assert_equal 10_00, attributes[:price_cents]
    end
  end

  test "source attribution" do
    donuts_location, kasper_location = [accounts.method(:kaspers_donuts), users.method(:kasper)].map(&:source_location)
    assert_match "db/seeds/accounts/kaspers_donuts.rb", donuts_location.first
    assert_match "db/seeds/accounts/kaspers_donuts.rb", kasper_location.first
    assert_operator donuts_location.second, :<, kasper_location.second

    administratorship_location, basic_location = [administratorships.method(:kasper_administratorship), menus.method(:basic)].map(&:source_location)
    assert_match "db/seeds/accounts/kaspers_donuts.rb", administratorship_location.first
    assert_match "db/seeds/accounts/kaspers_donuts.rb", basic_location.first
    assert_operator administratorship_location.second, :<, basic_location.second

    assert_match "db/seeds/data/plans.rb",      plans.method(:basic).source_location.first
    assert_match "db/seeds/test/data/plans.rb", plans.method(:test_premium).source_location.first
    assert_match "db/seeds/test/data/users.rb", users.method(:test_user).source_location.first
  end

  test "can't use labels within tests" do
    assert_raise ArgumentError do
      users.label kasper_2: users.kasper
    end
  end

  test "updating fixture" do
    users.kasper.update name: "Kasper2"
    assert_equal "Kasper2", users.kasper.name
  end

  test "upserting vs updating" do
    assert_equal "Basic", plans.basic.title

    error = assert_raises RuntimeError do
      plans.create title: "foo", price_cents: 0
    end
    assert_equal "after_save", error.message
  end

  test "respond_to_missing?" do
    mod = Oaken::Seeds.dup
    mod.undef_method :users # Remove built method
    assert mod.respond_to?(:users) # Now respond_to_missing? hits.
    refute mod.respond_to?(:hmhm)
  end

  test "raises when no files found to seed" do
    assert_raise(Oaken::Loader::NoSeedsFoundError) { seed "test/cases/missing" }.tap do |error|
      assert_match %r|found no seed files for "test/cases/missing"|, error.message
    end

    assert_raise(Oaken::Loader::NoSeedsFoundError) { seed :first_missing, :second_missing }.tap do |error|
      assert_match /found no seed files for :first_missing/, error.message
    end
  end
end

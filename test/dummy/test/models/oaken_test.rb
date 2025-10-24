require "test_helper"

class OakenTest < ActiveSupport::TestCase
  test "version number" do
    refute_nil ::Oaken::VERSION
  end

  test "replacing loader" do
    old_loader, Oaken.loader = Oaken.loader, Oaken.with(lookup_paths: name)
    assert_equal [name], Oaken.lookup_paths
  ensure
    Oaken.loader = old_loader
  end

  test "accessing fixture" do
    assert_equal "Kasper", users.kasper.name
    assert users.kasper.admin?
    assert_equal "Coworker", users.coworker.name
    assert users.coworker.mod?

    assert_equal users.named_coworker.type.first, users.coworker

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

  test "with - labeled via helper method" do
    assert_respond_to users, :created_from_with
    assert_equal "With User", users.created_from_with.name
    assert_equal "with-user@example.com", users.created_from_with.email_address
  end

  test "with - yields" do
    with_yielded = nil
    users.with { with_yielded = _1 } => with

    assert with
    assert_equal with, with_yielded
  end

  test "with - inherits helper methods" do
    assert_respond_to users.with, :create_labeled
  end

  test "with - defaults" do
    emails = 1.step
    with = users.with name: "with default 1", email_address: -> { "with#{emails.next}@example.com" }
    refute_equal users.defaults, with.defaults

    user = with.create
    assert_equal "with default 1", user.name
    assert_equal "with1@example.com", user.email_address

    user = with.create name: "with overriden"
    assert_equal "with overriden", user.name
    assert_equal "with2@example.com", user.email_address

    user = users.create # Check that we didn't pollute `users`.
    assert_match /Customer/, user.name
    assert_match /email_address\d+@example\.com/, user.email_address
  end

  test "can't use labels within tests" do
    assert_raise ArgumentError, match: /define labelled records outside of tests/ do
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
end

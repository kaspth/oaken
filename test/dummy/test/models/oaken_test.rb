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

  test "source attribution" do
    donuts_location, kasper_location = [accounts.method(:kaspers_donuts), users.method(:kasper)].map(&:source_location)
    assert_match "db/seeds/accounts/kaspers_donuts.rb", donuts_location.first
    assert_match "db/seeds/accounts/kaspers_donuts.rb", kasper_location.first

    assert_operator donuts_location.second, :<, kasper_location.second

    assert_match "db/seeds/data/plans.rb", plans.method(:basic).source_location.first
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
end

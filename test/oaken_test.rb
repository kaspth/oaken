# frozen_string_literal: true

require "test_helper"

class OakenTest < Oaken::Test
  class SomeObject; end

  def test_register
    Oaken::Data.memory.register SomeObject
    assert_respond_to self, :oaken_test_some_objects
  end


  def test_that_it_has_a_version_number
    refute_nil ::Oaken::VERSION
  end

  def test_helper_methods
    assert_equal 2, accounts.increment_counter # We start at 2 since the seeds file state should pass into here.
    assert_equal 3, accounts.increment_counter

    assert_raise NoMethodError do
      users.increment_counter
    end
  end

  def test_accessing_fixture
    assert_equal "Kasper", users.kasper.name
    assert_equal "Coworker", users.coworker.name

    assert_equal [accounts.business], users.kasper.accounts
    assert_equal [accounts.business], users.coworker.accounts
    assert_equal [users.kasper, users.coworker], accounts.business.users
  end

  def test_default_attributes
    users.with name: -> { id.to_s.humanize }, accounts: [accounts.update(:home_co, name: "Home Co.")] do
      users.update :homer
    end
    assert_equal "Homer", users.homer.name
    assert_equal [accounts.home_co], users.homer.accounts
  end

  def test_updating_fixture
    kasper = users.update :kasper, name: "Kasper2"
    assert_equal "Kasper2", kasper.name
  end

  def test_upserting_vs_updating
    assert_equal "Basic", plans.basic.title

    error = assert_raises RuntimeError do
      plans.update :salty, title: "foo", price_cents: 0
    end
    assert_equal "after_save", error.message
  end
end

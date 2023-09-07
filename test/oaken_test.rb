# frozen_string_literal: true

require "test_helper"

class OakenTest < Oaken::Test
  class SomeObject; end

  def test_register
    Oaken::Seeds.memory.register SomeObject
    assert_respond_to self, :oaken_test_some_objects
  end


  def test_that_it_has_a_version_number
    refute_nil ::Oaken::VERSION
  end

  def test_accessing_fixture
    assert_equal "Kasper", users.kasper.name
    assert_equal "Coworker", users.coworker.name

    assert_equal [accounts.business], users.kasper.accounts
    assert_equal [accounts.business], users.coworker.accounts
    assert_equal [users.kasper, users.coworker], accounts.business.users
  end

  def test_default_attributes
    homer, home_co = nil, accounts.create(name: "Home Co.")

    users.with accounts: [home_co] do
      homer = users.create name: "Homer"
    end
    assert_equal "Homer", homer.name
    assert_equal [home_co], homer.accounts
  end

  def test_updating_fixture
    users.kasper.update name: "Kasper2"
    assert_equal "Kasper2", users.kasper.name
  end

  def test_upserting_vs_updating
    assert_equal "Basic", plans.basic.title

    error = assert_raises RuntimeError do
      plans.create title: "foo", price_cents: 0
    end
    assert_equal "after_save", error.message
  end
end

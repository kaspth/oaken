require "test_helper"

class Oaken::LoaderTest < ActiveSupport::TestCase
  test "attr_readers" do
    assert_equal ["db/seeds", "db/seeds/test"], Oaken.loader.lookup_paths
    assert_equal Oaken::Seeds, Oaken.loader.context
  end

  test "glob" do
    paths = Oaken.glob(:accounts).map(&:to_s)
    assert_includes paths, "db/seeds/accounts/demo.rb"
    assert_includes paths, "db/seeds/accounts/kaspers_donuts.rb"
  end

  test "with + lookup_paths" do
    loader = Oaken.with(lookup_paths: "test/seeds")
    assert_equal ["test/seeds"], loader.lookup_paths
    assert_equal ["db/seeds", "db/seeds/test"], Oaken.loader.lookup_paths

    loader.with.tap { _1.lookup_paths.clear }
    assert_equal ["test/seeds"], loader.lookup_paths
  end

  test "with + context" do
    context = Module.new
    loader = Oaken.with(lookup_paths: "test/seeds", context:)
    assert_equal context, loader.context
    assert_equal Oaken::Seeds, Oaken.loader.context
  end

  test "with + defaults don't carry over" do
    loader = Oaken.with.tap { _1.defaults name: "Someone" }
    assert_empty loader.with.defaults
  end

  test "with + locator" do
    locator = Class.new { attr_accessor :located; alias_method :locate, :located= }.new
    Oaken.with(locator:).locate(:accounts)
    assert_equal locator.located, :accounts
  end

  test "with + provider" do
    context = Module.new
    provider = Struct.new(:loader, :type)
    loader = Oaken.with(provider:, context:).tap { _1.register User }

    instance = Class.new.include(loader.context).new
    assert_respond_to instance, :users
    assert_kind_of provider, instance.users
    assert_equal loader, instance.users.loader
    assert_equal User, instance.users.type
  end
end

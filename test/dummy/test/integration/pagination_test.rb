require "test_helper"

class PaginationTest < ActiveSupport::TestCase
  seed "cases/pagination"

  test "pagination sorta" do
    assert_operator Order.count, :>=, 100
  end

  test "pagination loading from sql case" do
    assert User.find_by(name: "pagination.sql")
  end
end

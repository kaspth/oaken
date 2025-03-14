require "test_helper"

class Oaken::TypeTest < ActiveSupport::TestCase
  test "with zero segments" do
    type = Oaken::Type.for("users")

    assert_consts type, ["User"]
    assert_equal User, type.locate
  end

  test "with one segment" do
    type = Oaken::Type.for("menu_items")

    assert_consts type, [
      "Menu::Item",
      "MenuItem"
    ]
    assert_equal Menu::Item, type.locate
  end

  test "with two segments" do
    type = Oaken::Type.for("menu_item_details")

    assert_consts type, [
      "Menu::Item::Detail",
      "Menu::ItemDetail",
      "MenuItem::Detail",
      "MenuItemDetail"
    ]
    assert_equal Menu::Item::Detail, type.locate
  end

  test "with three segments" do
    type = Oaken::Type.for("menu_item_detail_segments")

    assert_consts type, [
      "Menu::Item::Detail::Segment",
      "Menu::Item::DetailSegment",
      "Menu::ItemDetail::Segment",
      "Menu::ItemDetailSegment",
      "MenuItem::Detail::Segment",
      "MenuItem::DetailSegment",
      "MenuItemDetail::Segment",
      "MenuItemDetailSegment"
    ]
    assert_nil type.locate
  end

  test "with four segments" do
    error = assert_raises ArgumentError do
      Oaken::Type.for("this_has_four_segments_total").possible_consts.to_a
    end
    assert_match /can't resolve this_has_four_segments_total to an object/, error.message
  end

  def assert_consts(type, expected)
    assert_equal expected, type.possible_consts.to_a
  end
end

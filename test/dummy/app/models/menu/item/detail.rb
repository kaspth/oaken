class Menu::Item::Detail < ApplicationRecord
  belongs_to :menu_item, class_name: "Menu::Item"
end

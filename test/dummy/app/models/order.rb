class Order < ApplicationRecord
  belongs_to :user
  belongs_to :item, class_name: "Menu::Item"
end

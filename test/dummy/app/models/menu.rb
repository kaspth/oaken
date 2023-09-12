class Menu < ApplicationRecord
  belongs_to :account
  has_many :items, class_name: "Menu::Item", dependent: :destroy
end

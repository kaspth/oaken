class Account < ApplicationRecord
  has_many :administratorships
  has_many :users, through: :administratorships

  has_many :menus
end

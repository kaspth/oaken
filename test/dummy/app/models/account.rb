class Account < ApplicationRecord
  has_many :administratorships
  has_many :users, through: :administratorships
end

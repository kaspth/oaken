class User < ApplicationRecord
  has_many :administratorships
  has_many :accounts, through: :administratorships
end

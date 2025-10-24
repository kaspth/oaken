class User < ApplicationRecord
  has_many :administratorships
  has_many :accounts, through: :administratorships

  scope :named_coworker, -> { where(name: "Coworker") }

  enum :role, %w[admin mod plain].index_by(&:itself)
end

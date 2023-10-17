class Plan < ApplicationRecord
  after_save { raise "after_save" }
end

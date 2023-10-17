class CreatePlans < ActiveRecord::Migration[7.0]
  def change
    create_table :plans do |t|
      t.string :title, null: false
      t.integer :price_cents, null: false

      t.timestamps
    end
  end
end

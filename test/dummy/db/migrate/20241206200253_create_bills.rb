class CreateBills < ActiveRecord::Migration[7.2]
  def change
    create_table :bills, primary_key: [:order_id, :user_id] do |t|
      t.references :order, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :total

      t.timestamps
    end
  end
end

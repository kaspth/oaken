class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: {to_table: :menu_items}

      t.timestamps
    end
  end
end

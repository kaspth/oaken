class CreateMenuItems < ActiveRecord::Migration[7.0]
  def change
    create_table :menu_items do |t|
      t.references :menu, null: false, foreign_key: true
      t.string :name
      t.integer :price_cents

      t.timestamps
    end
  end
end

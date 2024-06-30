class CreateMenuItemDetails < ActiveRecord::Migration[7.1]
  def change
    create_table :menu_item_details do |t|
      t.references :menu_item, null: false, foreign_key: true
      t.text :description,     null: false

      t.timestamps
    end
  end
end

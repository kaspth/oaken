class CreateMenus < ActiveRecord::Migration[7.0]
  def change
    create_table :menus do |t|
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end

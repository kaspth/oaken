class CreateMenus < ActiveRecord::Migration[7.0]
  def change
    create_table :menus do |t|
      t.references :account, null: false, foreign_key: true, type: :string

      t.timestamps
    end
  end
end

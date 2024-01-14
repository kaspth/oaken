class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email_address, null: false

      t.timestamps

      t.index :email_address, unique: true
    end
  end
end

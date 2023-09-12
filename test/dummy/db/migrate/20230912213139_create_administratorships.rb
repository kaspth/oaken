class CreateAdministratorships < ActiveRecord::Migration[7.0]
  def change
    create_table :administratorships do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end

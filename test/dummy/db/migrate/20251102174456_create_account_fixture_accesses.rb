class CreateAccountFixtureAccesses < ActiveRecord::Migration[8.0]
  def change
    create_table :account_fixture_accesses do |t|
      t.references :account, null: false, index: true
      t.string :name

      t.timestamps
    end
  end
end

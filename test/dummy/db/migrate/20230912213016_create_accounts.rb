class CreateAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :accounts, id: false do |t|
      t.primary_key :id, :string, default: -> { "ULID()" }
      t.string :name

      t.timestamps
    end
  end
end

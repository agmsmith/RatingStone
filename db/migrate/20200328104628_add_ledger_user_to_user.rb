class AddLedgerUserToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :ledger_user_id, :bigint, null: true,
     comment: "Twin Ledger record that corresponds to this user."
    add_index :users, :ledger_user_id, unique: true
  end
end

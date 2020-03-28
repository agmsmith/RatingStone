class AddLedgerUserToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :ledger_user_id, :bigint, comment: "Twin Ledger record that corresponds to this user.  Not using belongs_to/has_one/foreign keys to save database column space."
  end
end

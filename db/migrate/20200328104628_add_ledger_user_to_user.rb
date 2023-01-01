class AddLedgerUserToUser < ActiveRecord::Migration[7.0]
  def change
    add_reference :users, :ledger_user, null: true, index: {unique: true}, foreign_key: {to_table: :ledger_bases, name: "fk_rails_userledgeruser"}, comment: "Twin LedgerUser record that corresponds to this user or NULL if none yet.  Will be the original version of the LedgerUser; look up the latest version LedgerUser to find the one that has the same name and e-mail as this User record."
  end
end

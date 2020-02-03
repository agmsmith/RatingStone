class AddLink1ToLedgerBase < ActiveRecord::Migration[6.0]
  def change
    add_reference :ledger_bases, :link1, null: true, foreign_key: {to_table: :link_bases, name: "fk_rails_ledgerlink1"}, comment: "Points to a generic LinkBase object (or subclass)."
  end
end

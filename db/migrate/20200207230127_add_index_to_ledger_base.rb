class AddIndexToLedgerBase < ActiveRecord::Migration[6.0]
  def change
    add_index :ledger_bases, :string1
    add_index :ledger_bases, :string2
    add_index :ledger_bases, :number1
  end
end

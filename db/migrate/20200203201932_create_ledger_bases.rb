class CreateLedgerBases < ActiveRecord::Migration[6.0]
  def change
    create_table :ledger_bases, force: false, comment: "Ledger objects base class and record.  Don't force: cascade deletes since it is a write-once ledger." do |t|
      t.string :type, default: "LedgerBase", comment: "Names the ActiveRecord subclass used to load this row."
      t.boolean :bool1, default: false, comment: "Generic boolean, defined by subclasses."
      t.datetime :date1, default: DateTime.new(1,1,1,0,0,0), comment: "Generic date and time from year 0 to year 9999, defined by subclasses."
      t.integer :number1, default: 0, comment: "Generic number for counting things, defined by subclasses."
      t.string :string1, default: "", comment: "Generic string (up to 255 bytes), defined by subclasses."
      t.string :string2, default: "", comment: "Generic string (up to 255 bytes), defined by subclasses."
      t.text :text1, default: "", comment: "Generic text (lots of characters), defined by subclasses."
      t.references :creator, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledgercreator"}, comment: "Identifies the user who created this record."
      t.references :original, null: true, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledgeroriginal"}, comment: "Points to the original version of this record, or NULL if this is the original one."
      t.references :amended, null: true, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledgeramended"}, comment: "Points to the latest version of this record, or NULL if this is not the original record."
      t.references :deleted, null: true, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledgerdeleted"}, comment: "Points to one of the LedgerDelete records that is currently deleting this record, otherwise NULL (record is alive)."
      t.references :ledger1, null: true, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledger1"}, comment: "Generic reference to some other LedgerBase record, can be NULL, defined by subclasses."
      t.float :current_down_points, default: 0.0
      t.float :current_meh_points, default: 0.0
      t.float :current_up_points, default: 0.0
      t.timestamps
    end
  end
end

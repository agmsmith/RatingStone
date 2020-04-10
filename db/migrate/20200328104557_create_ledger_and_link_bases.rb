class CreateLedgerAndLinkBases < ActiveRecord::Migration[6.0]
  def change
    create_table :ledger_bases, force: false, comment: "Ledger objects base class and record.  Don't force: cascade deletes since this is a write-once ledger." do |t|
      t.string :type, default: "LedgerBase", comment: "Names the ActiveRecord subclass used to load this row, turning on single table inheritance."
      t.boolean :bool1, default: false, comment: "Generic boolean, defined by subclasses."
      t.integer :number1, default: 0, comment: "Generic number for counting things, defined by subclasses."
      t.string :string1, default: "", comment: "Generic string (up to 255 bytes), defined by subclasses."
      t.string :string2, default: "", comment: "Generic string (up to 255 bytes), defined by subclasses."
      t.text :text1, default: "", comment: "Generic text (lots of characters), defined by subclasses."
      t.references :creator, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledgercreator"}, comment: "Identifies the user who created this record."
      t.references :amended, null: true, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledgeramended"}, comment: "Points to the latest version of this record, or NULL if this is not the original record."
      t.boolean :deleted, default: false, comment: "True if there is a LedgerDelete record that is currently deleting this record, otherwise false (record is alive)."
      t.references :original, null: true, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledgeroriginal"}, comment: "Points to the original version of this record, or equal to id if this is the original one.  NULL if not initialised (should be a copy of the id of the record)."
      t.float :current_down_points, default: 0.0, comment: "Number of rating points in the down direction for this object. This is the current total, including fading over time (recalculated at the beginning of the week in the awards ceremony) plus new ratings applied this week."
      t.float :current_meh_points, default: 0.0, comment: "Number of rating points in the meh non-direction for this object. This is the current total, including fading over time (recalculated at the beginning of the week in the awards ceremony) plus new ratings applied this week."
      t.float :current_up_points, default: 0.0, comment: "Number of rating points in the up direction for this object. This is the current total, including fading over time (recalculated at the beginning of the week in the awards ceremony) plus new ratings applied this week."
      t.datetime :date1, null: true, comment: "Generic date and time from year 0 to year 9999, defined by subclasses."
      t.timestamps
    end

    add_index :ledger_bases, :string1
    add_index :ledger_bases, :string2
    add_index :ledger_bases, :number1

    create_table :link_bases, force: false, comment: "LinkBase base class and record for linking LedgerObjects together." do |t|
      t.string :type, default: "LinkBase", comment: "Names the ActiveRecord subclass used to load this row, turning on single table inheritance."
      t.references :parent, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_linkparent"}, comment: "Points to the LedgerBase object (or subclass) which is usually the main one in the association."
      t.references :child, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_linkchild"}, comment: "Points to the LedgerBase object (or subclass) which is the child in the association."
      t.references :creator, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_linkcreator"}, comment: "Identifies the User who created this link."
      t.boolean :deleted, default: false, comment: "True if there is a LedgerDelete record that deletes this record, otherwise false (this record is alive)."
      t.boolean :pending, default: false, comment: "True if permission is currently denied. The link record exists but it can’t be traversed (sort of like being deleted) until someone gives permission."
      t.float :rating_points_spent, default: 0.0, comment: "The number of points spent on making this link by the creator."
      t.float :rating_points_boost_child, default: 0.0, comment: "The number of points used to boost the rating of the child object."
      t.float :rating_points_boost_parent, default: 0.0, comment: "The number of points used to boost the rating of the child object."
      t.string :rating_direction, default: "M", comment: "Use U for up, D for down or M for meh."
      t.integer :award_number, default: 0, comment: "The week's award number when this record was created, 0 if before time starts."
      t.timestamps
    end

    create_table :aux_links, force: false, comment: "AuxLink class and record for connecting LedgerObjects (usually LedgerDelete) to LinkBase records (usually links being deleted)." do |t|
      t.references :parent, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_auxlinkparent"}, comment: "Points to the LedgerBase object (or subclass) which has the delete or undelete or give permission order."
      t.references :child, null: false, foreign_key: {to_table: :link_bases, name: "fk_rails_auxlinkchild"}, comment: "Points to the child LinkBase object (or subclass) which is being modified by the parent."
    end

    create_table :aux_ledgers, force: false, comment: "AuxLedger class and record for connecting LedgerBase records (usually LedgerDelete) to other LedgerBase records (usually objects being deleted)." do |t|
      t.references :parent, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_auxledgerparent"}, comment: "Points to the LedgerBase object (or subclass) which has the delete or undelete order."
      t.references :child, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_auxledgerchild"}, comment: "Points to the child LedgerBase object (or subclass) which is being modified by the parent."
    end
  end
end


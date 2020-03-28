class CreateLedgerAndLinkBases < ActiveRecord::Migration[6.0]
  def change
    create_table :ledger_bases, force: false, comment: "Ledger objects base class and record.  Don't force: cascade deletes since this is a write-once ledger." do |t|
      t.string :type, default: "LedgerBase", comment: "Names the ActiveRecord subclass used to load this row, turning on single table inheritance."
      t.boolean :bool1, default: false, comment: "Generic boolean, defined by subclasses."
      t.datetime :date1, default: DateTime.new(1,1,1,0,0,0), comment: "Generic date and time from year 0 to year 9999, defined by subclasses."
      t.integer :number1, default: 0, comment: "Generic number for counting things, defined by subclasses."
      t.string :string1, default: "", comment: "Generic string (up to 255 bytes), defined by subclasses."
      t.string :string2, default: "", comment: "Generic string (up to 255 bytes), defined by subclasses."
      t.text :text1, default: "", comment: "Generic text (lots of characters), defined by subclasses."
      t.references :creator, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledgercreator"}, comment: "Identifies the user who created this record."
      t.references :original, null: true, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledgeroriginal"}, comment: "Points to the original version of this record, or NULL if this is the original one."
      t.references :amended, null: true, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledgeramended"}, comment: "Points to the latest version of this record, or NULL if this is not the original record."
      t.references :ledger1, null: true, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledger1"}, comment: "Generic reference to some other LedgerBase record, can be NULL, defined by subclasses."
      t.boolean :deleted, default: false, comment: "True if there is a LedgerDelete record that is currently deleting this record, otherwise false (record is alive)."
      t.float :current_down_points, default: 0.0, comment: "Number of rating points in the down direction for this object. This is the current total, including fading over time (recalculated at the beginning of the week in the awards ceremony) plus new ratings applied this week."
      t.float :current_meh_points, default: 0.0, comment: "Number of rating points in the meh non-direction for this object. This is the current total, including fading over time (recalculated at the beginning of the week in the awards ceremony) plus new ratings applied this week."
      t.float :current_up_points, default: 0.0, comment: "Number of rating points in the up direction for this object. This is the current total, including fading over time (recalculated at the beginning of the week in the awards ceremony) plus new ratings applied this week."
      t.timestamps
    end

    add_index :ledger_bases, :string1
    add_index :ledger_bases, :string2
    add_index :ledger_bases, :number1

    create_table :link_bases, force: false, comment: "LinkBase base class and record for linking LedgerObjects together." do |t|
      t.string :type, default: "LinkBase", comment: "Names the ActiveRecord subclass used to load this row, turning on single table inheritance."
      t.references :parent, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_linkparent"}, comment: "Points to the LedgerBase object (or subclass) which is usually the main one in the association."
      t.references :child_ledger, null: true, foreign_key: {to_table: :ledger_bases, name: "fk_rails_linkchildledger"}, comment: "Points to the LedgerBase object (or subclass) which is the child in the association.  Used by the LinkBaseObject subclass."
      t.references :child_link, null: true, foreign_key: {to_table: :link_bases, name: "fk_rails_linkchildlink"}, comment: "Points to the LinkBase object (or subclass) which is the child in the association.  Used by the LinkBaseLink subclass."
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
  end
end


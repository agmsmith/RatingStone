class CreateLedgerAndLinkBases < ActiveRecord::Migration[7.0]
  def change
    create_table :ledger_bases, force: false, comment: "Ledger objects base class and record.  Don't force: cascade deletes since this is a write-once ledger where usually nothing gets deleted (except during points expired object garbage collection)." do |t|
      t.string :type, default: "LedgerBase", comment: "Names the ActiveRecord subclass used to load this row, turning on single table inheritance."
      t.references :original, null: true, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledgeroriginal"}, comment: "Points to the original version of this record, or equal to id if this is the original one.  NULL if not initialised (should be a copy of the id of this record)."
      t.references :amended, null: true, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledgeramended"}, comment: "Points to the latest version of this record, or NULL if this is not the original record."
      t.boolean :deleted, default: false, comment: "True if there is a LedgerDelete record that is currently deleting this record, otherwise false (record is alive)."
      t.boolean :expired_now, default: false, comment: "When true, the record will be permanently deleted (not just marked as deleted) at the next award ceremony."
      t.boolean :expired_soon, default: false, comment: "When true a warning message is displayed to users when viewing this object (suggesting that they spend some points to revive it), doesn’t affect how the record is treated."
      t.boolean :has_owners, default: false, comment: "True if there is one or more LinkOwner records (even deleted ones) that references this record.  False if there are none, which means we can skip searching for LinkOwner records every time we check permissions, which saves a lot of database queries!"
      t.boolean :is_latest_version, default: true, comment: "True if the record is the latest version of the object.  False otherwise.  Caches the result of looking up the original object and seeing which record is the latest, so we have less overhead when displaying only the latest versions in a list of posts.  Also lets us skip older versions directly in an SQL query."
      t.references :creator, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_ledgercreator"}, comment: "Identifies the user who created this record, using their original ID."
      t.boolean :bool1, default: false, comment: "Generic boolean, defined by subclasses."
      t.bigint :number1, default: 0, comment: "Generic number for counting things, or referencing other database tables, usage defined by subclasses."
      t.string :string1, default: "", comment: "Generic string (up to 255 bytes), defined by subclasses."
      t.string :string2, default: "", comment: "Generic string (up to 255 bytes), defined by subclasses."
      t.text :text1, default: "", comment: "Generic text (lots of characters), defined by subclasses."
      t.datetime :date1, null: true, comment: "Generic date and time from year 0 to year 9999, defined by subclasses."
      t.float :current_down_points, default: 0.0, comment: "Number of rating points in the down direction for this object. This is the current total, including fading over time (recalculated at the beginning of the week in the awards ceremony) plus new ratings applied this week."
      t.float :current_meh_points, default: 0.0, comment: "Number of rating points in the meh non-direction for this object. This is the current total, including fading over time (recalculated at the beginning of the week in the awards ceremony) plus new ratings applied this week."
      t.float :current_up_points, default: 0.0, comment: "Number of rating points in the up direction for this object. This is the current total, including fading over time (recalculated at the beginning of the week in the awards ceremony) plus new ratings applied this week."
      t.integer :current_ceremony, default: -1, comment: "The number of the awards ceremony that the current points were calculated for.  0 means before the first ceremony.  Set to -1 to force a recalculation of current points.  If it is less than the most recent ceremony's number, the points just need an update recalculation."
      t.integer :original_ceremony, default: -1, comment: "The number of the awards ceremony immediately prior to the creation of this object.  0 if before the first awards ceremony.  Negative is an initialisation bug.  Theoretically you could figure it out from the record creation date."
      t.timestamps
    end

    add_index :ledger_bases, :string1
    add_index :ledger_bases, :string2
    add_index :ledger_bases, :number1

    create_table :link_bases, force: false, comment: "LinkBase base class and record for linking LedgerObjects together." do |t|
      t.string :type, default: "LinkBase", comment: "Names the ActiveRecord subclass used to load this row, turning on single table inheritance."
      t.references :parent, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_linkparent"}, comment: "Points to the parent LedgerBase object (or subclass) which is usually the main one or older one in the association.  Uses the original ID of the parent."
      t.references :child, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_linkchild"}, comment: "Points to the child LedgerBase object (or subclass) which is the child in the association.  Uses the original ID of the child."
      t.references :creator, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_linkcreator"}, comment: "Identifies the User who created this link, using their original ID."
      t.bigint :number1, default: 0, comment: "Generic number for counting things, or referencing other database tables, usage defined by subclasses."
      t.string :string1, default: "", comment: "Generic string (up to 255 bytes), defined by subclasses."
      t.boolean :deleted, default: false, comment: "True if there is a LedgerDelete record that deletes this record, otherwise false (this record is alive)."
      t.boolean :approved_parent, default: false, comment: "True if the link to the parent object has been approved.  False means it's pending; the link record exists but it can't be traversed (sort of like being deleted) until someone gives permission via LedgerApprove."
      t.boolean :approved_child, default: false, comment: "True if the link to the child object has been approved.  False means it's pending; the link record exists but it can't be traversed (sort of like being deleted) until someone gives permission via LedgerApprove."
      t.float :rating_points_spent, default: 0.0, comment: "The number of points spent on making this link by the creator.  Includes transaction fees."
      t.float :rating_points_boost_parent, default: 0.0, comment: "The number of points used to boost the rating of the parent object."
      t.float :rating_points_boost_child, default: 0.0, comment: "The number of points used to boost the rating of the child object."
      t.string :rating_direction_parent, default: "M", comment: "Use U for up, D for down or M for meh.  Controls how points spent modify the parent's rating."
      t.string :rating_direction_child, default: "M", comment: "Use U for up, D for down or M for meh.  Controls how points spent modify the child's rating."
      t.integer :original_ceremony, default: -1, comment: "The week's award ceremony number when this record was created, 0 if before any ceremonies have been done.  -1 if it hasn't been set yet (in which case it will soon be set and the point boosts added to the parent and child objects)."
      t.timestamps
    end

    add_index :link_bases, :string1
    add_index :link_bases, :number1

    create_table :aux_links, force: false, comment: "AuxLink class and record for connecting LedgerObjects (usually LedgerDelete or LedgerApprove) to LinkBase records (usually links being deleted or approved)." do |t|
      t.references :parent, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_auxlinkparent"}, comment: "Points to the LedgerBase object (or subclass) which has the delete or undelete or give permission order."
      t.references :child, null: false, foreign_key: {to_table: :link_bases, name: "fk_rails_auxlinkchild"}, comment: "Points to the child LinkBase object (or subclass) which is being modified by the parent."
    end

    create_table :aux_ledgers, force: false, comment: "AuxLedger class and record for connecting LedgerBase records (usually LedgerDelete) to other LedgerBase records (usually objects being deleted)." do |t|
      t.references :parent, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_auxledgerparent"}, comment: "Points to the LedgerBase object (or subclass) which has the delete or undelete order."
      t.references :child, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_auxledgerchild"}, comment: "Points to the child LedgerBase object (or subclass) which is being modified by the parent."
    end
  end
end


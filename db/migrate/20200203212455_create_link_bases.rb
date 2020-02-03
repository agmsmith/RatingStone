class CreateLinkBases < ActiveRecord::Migration[6.0]
  def change
    create_table :link_bases, force: false, comment: "LinkBase base class and record for linking LedgerObjects together." do |t|
      t.string :type, default: "LinkBase", comment: "Names the ActiveRecord subclass used to load this row."
      t.references :parent, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_linkparent"}, comment: "Points to the LedgerBase object (or subclass) which is usually the main one in the association."
      t.references :child, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_linkchild"}, comment: "Points to the LedgerBase object (or subclass) which is the other one in the association."
      t.references :creator, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_linkcreator"}, comment: "Identifies the User who created this link."
      t.references :deleted, null: true, foreign_key: {to_table: :ledger_bases, name: "fk_rails_linkdeleted"}, comment: "Points to one of the LedgerUnlink or LedgerDelete records that deleted this record, otherwise NULL (this record is alive)."
      t.float :rating_points_spent, default: 0.0, comment: "The number of points spent on making this link by the creator."
      t.float :rating_points_boost, default: 0.0, comment: "The number of points used to boost the rating of the child object."
      t.string :rating_direction, default: "M", comment: "Use U for up, D for down or M for meh."
      t.integer :award_number, default: 0, comment: "The week's award number when this record was created, 0 if before time starts."
      t.timestamps
    end
  end
end

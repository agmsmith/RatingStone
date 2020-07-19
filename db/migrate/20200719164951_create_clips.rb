class CreateClips < ActiveRecord::Migration[6.0]
  def change
    create_table :clips, comment: "Clipboard for users to save items to before doing bulk operations with them." do |t|
      t.references :ledger_user_id, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_clipuser"}, comment: "ID number of the LedgerUser this clipboard belongs to."
      t.string :object_type, default: "", comment: "Class name of the object, like LedgerPost or LinkReply.  Helps identify which of ledger or link object ID from this record to use."
      t.references :ledger_object_id, null: true, foreign_key: {to_table: :ledger_bases, name: "fk_rails_clipledger"}, comment: "ID number of the object if it is a LedgerBase or subclass, or NULL."
      t.references :link_object_id, null: true, foreign_key: {to_table: :link_bases, name: "fk_rails_cliplink"}, comment: "ID number of the object if it is a LinkBase or subclass, or NULL."
      t.string :description, default: "", comment: "Short description of the object for display when we are showing the clipboard."
    end
  end
end

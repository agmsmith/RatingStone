class CreateGroupSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :group_settings, comment: "Extra information for each LedgerFullGroup object is stored in this table." do |t|
      t.references :ledger_full_group, null: false, foreign_key: {to_table: :ledger_bases, name: "fk_rails_groupsettingsgroup"}, comment: "Points to the LedgerFullGroup (a LedgerBase subclass) that this record contains the extra settings for."
      t.boolean :auto_approve_non_member_posts, default: false, comment: "True if posts attached to the group by a non-member are automatically approved (if they have enough points).  False means a moderator will need to approve them."
      t.boolean :auto_approve_member_posts, default: false, comment: "True if posts attached to the group by a member are automatically approved (if they have enough points).  False means a moderator will need to approve them."
      t.boolean :auto_approve_members, default: false, comment: "True if new member applications are automatically approved (if they have enough points).  False requires approval by a member moderator."
      t.float :min_points_non_member_post, default: 0.0, comment: "Minimum number of Up rating points needed when posting as a non-member to get automatic approval.  If they don't have enough, their post will need to be approved by a moderator.  Ignored if automatic approval is turned off."
      t.float :min_points_member_post, default: 0.0, comment: "Minimum number of Up rating points needed when posting as a member to get automatic approval.  If they don't have enough, their post will need to be approved by a moderator.  Ignored if automatic approval is turned off."
      t.float :min_points_membership, default: 0.0, comment: "Minimum number of Up rating points needed when applying to be a member to get automatic approval.  Ignored if automatic approval is turned off.  If they don't get automatically approved, a moderator will need to approve their request."
      t.string :wildcard_role_banned, default: "", comment: "Wildcard expression to identify people who are banned, in addition to explicit LinkRole records.  So we can ban friends of banned people, etc."
      t.string :wildcard_role_reader, default: "", comment: "Relationship expression specifying additional people who are allowed to read the group."
      t.string :wildcard_role_member, default: "", comment: "Relationship expression specifying additional people who are considered members of the group, even if they didn't apply."
      t.string :wildcard_role_message_moderator, default: "", comment: "Relationship expression specifying additional people who are allowed to moderate (approve/delete) messages."
      t.string :wildcard_role_meta_moderator, default: "", comment: "Relationship expression specifying additional people who are allowed to anonymously rate opinions about messages in this group."
      t.string :wildcard_role_member_moderator, default: "", comment: "Relationship expression specifying additional people who are allowed to moderate membership requests."
    end
  end
end

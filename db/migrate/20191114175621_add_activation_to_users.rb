class AddActivationToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :activation_digest, :string
    add_column :users, :activated, :boolean, default: false
    add_column :users, :activated_at, :datetime, comment: "Kind of a birthday for the account, when the user confirmed their e-mail address.  Used for annual rewards and that sort of thing."
  end
end

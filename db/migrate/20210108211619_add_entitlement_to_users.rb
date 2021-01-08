class AddEntitlementToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :entitlement_remaining, :float, default: 0.0, comment: "Number of entitlement points from the weekly awards ceremony which the user has remaining to spend."
  end
end

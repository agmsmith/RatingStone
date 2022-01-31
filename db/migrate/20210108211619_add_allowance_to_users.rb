class AddAllowanceToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :weeks_allowance, :float, default: 0.0, comment: "Number of bonus reputation points the user got for this week's allowance at the awards ceremony.  Limited to be between 0 and 100.  Mostly just for their information; the actual points are added to meh each week."
    add_column :users, :weeks_spending, :float, default: 0.0, comment: "Number of points the user has spent so far this week, reset to zero at the next ceremony.  May exceed their allowance if they spend up points too (if they have more up than down)."
  end
end

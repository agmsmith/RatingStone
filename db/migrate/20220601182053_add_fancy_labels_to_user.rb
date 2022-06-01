class AddFancyLabelsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :fancy_labels, :int, default: 0,
      comment: "0 for ASCII words to label things like Up/Meh/Down, Reply, Quote when displaying them to this user.  1 for short ASCII like ^~v for up/meh/down.  2 for UTF font icons.  Changeable in the user's profile settings."
  end
end

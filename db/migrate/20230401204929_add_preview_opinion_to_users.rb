class AddPreviewOpinionToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :preview_opinion, :boolean, default: false,
      comment: "TRUE to show an opinion editing form after doing a one click up/meh/down so that the user can customise the rating points and specify a reason.  FALSE to just create the opinion using various defaults."
  end
end

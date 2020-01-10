class AddImagesNumberToMicroposts < ActiveRecord::Migration[6.0]
  def change
    add_column :microposts, :images_number, :int, default: 0
  end
end

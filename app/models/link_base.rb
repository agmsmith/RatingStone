class LinkBase < ApplicationRecord
  belongs_to :parent
  belongs_to :child
  belongs_to :creator
  belongs_to :deleted
end

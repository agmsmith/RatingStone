# frozen_string_literal: true.

class LedgerList < LedgerBase
  alias_attribute :list_name, :string1

  has_many :link_list, class_name: :LinkList, foreign_key: :parent_id
  has_many :list_contents, through: :link_list, source: :child
end

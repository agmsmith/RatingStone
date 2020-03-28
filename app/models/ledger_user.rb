# frozen_string_literal: true

class LedgerUser < LedgerBase
  alias_attribute :name, :string1
  alias_attribute :email, :string2
  alias_attribute :birthday, :date1
  alias_attribute :user_id, :number1

  def user
    User.find(user_id)
  end
end

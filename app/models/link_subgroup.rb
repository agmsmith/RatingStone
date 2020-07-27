# frozen_string_literal: true

class LinkSubgroup < LinkBase
  before_create :set_default_description

  private

  def set_default_description
    return unless string1.empty?
    self.string1 = "#{child.latest_version.name} is a subgroup of " \
      "#{parent.latest_version.name}.".truncate(255)
  end
end

# frozen_string_literal: true

class LedgerPostsController < LedgerContentsController
  # See parent classes for generic create, edit, index and other methods.

  private

  ##
  # Returns the Ledger class that's appropriate for this controller to handle.
  # Can be used for creating new objects of the appropriate class.
  # FUTURE: Should preload subclasses here since this is often used just before
  # a database find_by.
  def ledger_class_for_controller
    LedgerPost
  end
end

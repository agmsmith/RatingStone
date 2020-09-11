class AddLatestVersionToLedgerBase < ActiveRecord::Migration[6.0]
  def change
    add_column :ledger_bases, :is_latest_version, :boolean, default: true,
      comment: "True if the record is the latest version of the object.  False otherwise.  Caches the result of looking up the original object and seeing which record is the latest, so we have less overhead when displaying only the latest versions in a list of posts."
  end
end

class RenameContributorsToAuthors < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :contributor, :author
  end
end

class AddVoterStateToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :voter, :boolean, default: false, null: false
  end
end

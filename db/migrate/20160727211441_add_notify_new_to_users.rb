class AddNotifyNewToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :notify_new, :boolean, default: true
  end
end

class AddLicenseAgreementToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :cla_accepted, :boolean, default: false
  end
end

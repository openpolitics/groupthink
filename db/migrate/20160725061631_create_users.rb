class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :login, null: false
      t.string :avatar_url
      t.boolean :contributor, default: false, null: false
      t.timestamps
    end
  end
end

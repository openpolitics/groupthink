# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :login, null: false
      t.string :avatar_url
      t.boolean :contributor, default: false, null: false
      t.timestamps
    end
  end
end

# frozen_string_literal: true

class AddUniqueIndexes < ActiveRecord::Migration[6.0]
  def change
    add_index :proposals, :number, unique: true
    add_index :users, [:login, :provider], unique: true
  end
end

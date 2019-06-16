# frozen_string_literal: true

class AddUserEmails < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :email, :string
  end
end

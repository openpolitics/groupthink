# frozen_string_literal: true

class CreatePullRequests < ActiveRecord::Migration[5.0]
  def change
    create_table :pull_requests do |t|
      t.integer :number, null: false
      t.string :state, null: false
      t.string :title, null: false
      t.references :proposer, null: false
      t.datetime :opened_at, null: false
      t.timestamps
    end
  end
end

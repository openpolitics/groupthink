class CreateProposals < ActiveRecord::Migration
  def change
    create_table :proposals do |t|
      t.integer :pull_request_number, null: false
      t.string :state, null: false
      t.string :title, null: false
      t.references :proposer, null: false
      t.timestamps
    end
  end
end

class CreateInteractions < ActiveRecord::Migration[5.0]
  def change
    create_table :interactions do |t|
      t.references :user, null: false
      t.references :pull_request, null: false
      t.string :last_vote
      t.timestamps
    end    
  end
end

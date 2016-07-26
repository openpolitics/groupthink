class RenamePullRequestsToProposals < ActiveRecord::Migration
  def change
    rename_table :pull_requests, :proposals
    rename_column :interactions, :pull_request_id, :proposal_id
  end
end

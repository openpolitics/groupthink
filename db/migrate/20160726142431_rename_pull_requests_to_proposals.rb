# frozen_string_literal: true

class RenamePullRequestsToProposals < ActiveRecord::Migration[5.0]
  def change
    rename_table :pull_requests, :proposals
    rename_column :interactions, :pull_request_id, :proposal_id
  end
end

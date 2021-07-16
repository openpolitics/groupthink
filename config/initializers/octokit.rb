# frozen_string_literal: true

Octokit.configure do |c|
  c.access_token = ENV.fetch("GITHUB_OAUTH_TOKEN")
end
Octokit.auto_paginate = true

# Set up repository for use by Groupthink

def create_label_if_missing(label:, colour:, description:)
  Octokit.label(Rails.application.config.groupthink[:github_repo], label)
rescue Octokit::NotFound
  Octokit.add_label(Rails.application.config.groupthink[:github_repo], label, colour,
description: description)
end

unless Rails.env.test?
  # Configure GitHub webhook automatically
  begin
    webhook_url = "#{Rails.application.config.groupthink[:site_url]}/webhook"
    Octokit.create_hook(
      Rails.application.config.groupthink[:github_repo], "web",
      {
        url: webhook_url,
        content_type: "form",
      },
      {
        events: ["issue_comment", "pull_request"],
        active: true,
      }
    )
  rescue Octokit::UnprocessableEntity
    # The hook already exists, no problem
    nil
  end
  # Enable issues and other repo-wide settings
  begin
    repo_options = {
      delete_branch_on_merge: true,
      has_issues: true,
      allow_squash_merge: false,
      allow_rebase_merge: false,
      has_wiki: false,
      has_projects: false,
    }
    Octokit.edit_repository(Rails.application.config.groupthink[:github_repo], repo_options)
    # Set up labels
    create_label_if_missing(label: "groupthink::proposal", colour: "d4c5f9",
description: "Proposals to be voted on in Groupthink")
    create_label_if_missing(label: "groupthink::idea", colour: "fbca04",
description: "Ideas for future proposals")
  rescue Octokit::UnprocessableEntity
    # We couldn't set the repo settings, but we don't want this to kill
    # startup, so carry on regardless
    nil
  end
end

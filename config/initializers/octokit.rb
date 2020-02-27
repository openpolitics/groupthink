# frozen_string_literal: true

Octokit.configure do |c|
  c.access_token = ENV.fetch("GITHUB_OAUTH_TOKEN")
end
Octokit.auto_paginate = true

# Set up repository for use by Groupthink

def create_label_if_missing(label:, colour:, description:)
  Octokit.label(ENV.fetch("GITHUB_REPO"),label)
rescue Octokit::NotFound
  Octokit.add_label(ENV.fetch("GITHUB_REPO"), label, colour, description: description)
end

unless Rails.env.test?
  create_label_if_missing(label: "groupthink::proposal", colour: "d4c5f9", description: "Proposals to be voted on in Groupthink")
  create_label_if_missing(label: "groupthink::idea", colour: "fbca04", description: "Ideas for future proposals")
end

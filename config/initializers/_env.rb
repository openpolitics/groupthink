# frozen_string_literal: true

Rails.application.config.groupthink = {}
{
  ALL_AUTHORS_CAN_VOTE: false,
  BOOTSTRAP_CSS_URL: "//maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css",
  EMAIL_DOMAIN: nil,
  GITHUB_REPO: nil,
  SITE_URL: nil,
}.each do |name, default|
  Rails.application.config.groupthink[name.to_s.underscore] = ENV.fetch(name.to_s, default)
end

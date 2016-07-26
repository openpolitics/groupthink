Octokit.configure do |c|
  c.access_token = ENV['GITHUB_OAUTH_TOKEN']
end
Octokit.auto_paginate = true
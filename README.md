[![Build Status](https://travis-ci.org/openpolitics/votebot.png?branch=master)](https://travis-ci.org/openpolitics/votebot) [![Coverage Status](https://coveralls.io/repos/github/openpolitics/votebot/badge.svg?branch=master)](https://coveralls.io/github/openpolitics/votebot?branch=master) [![Dependency Status](https://gemnasium.com/badges/github.com/openpolitics/votebot.svg)](https://gemnasium.com/github.com/openpolitics/votebot) [![Code Climate](https://codeclimate.com/github/openpolitics/votebot/badges/gpa.svg)](https://codeclimate.com/github/openpolitics/votebot)


# Votebot

An app which monitors manifesto PRs, and decides if consensus has been reached.

## Usage

### Voting rules

## Get your own!

This isn't a simple process, unfortunately, but we'll help you through as best we can...

### Set up a GitHub repository for your content

You can use Votebot to edit any GitHub repository you like, but we've set up a template site using GitHub Pages and Jekyll to get you started. Hit "Fork" below to get a copy for yourself, ready to go:

<!-- Place this tag where you want the button to render. -->
<a class="github-button" href="https://github.com/openpolitics/template/fork" data-icon="octicon-repo-forked" data-style="mega" data-count-href="/openpolitics/template/network" data-count-api="/repos/openpolitics/template#forks_count" data-count-aria-label="# forks on GitHub" aria-label="Fork openpolitics/template on GitHub">Fork</a>
<script async defer src="https://buttons.github.io/buttons.js"></script>

Then visit the cloned repository's settings page, and:

* rename it to something more useful than `template`
* enable GitHub pages on the `master` branch

### Create a GitHub API token

Visit the [Personal Access Tokens page](https://github.com/settings/tokens) on your GitHub account to create a token for accessing the API. Generate a new token. You'll need to allow the following permissions:

* public_repo
* repo:status
* user:email 
* write:repo_hook

Keep hold of the generated token - you'll need it in a minute.

### Create a GitHub OAuth application

Visit the [Developer applications page](https://github.com/settings/developers) on your GitHub account to set up user login via GitHub. Register a new application; in the homepage and callback URLs enter the URL of the application you are about to deploy. Yes, that's slightly tricky. It will be something like `https://your-unique-votebot-app-name.herokuapp.com`.

Again, keep hold of the client ID and secret. You'll need them in the next step.

### Deploy the code to Heroku

Hit this big deploy button here: 

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

Then, enter all the relevant details. Use the same app name you did in the step above, `your-unique-votebot-app-name`. If it's taken, don't worry, you can go back and edit the GitHub application settings later.

Enter the personal access token, client ID, and secret from the previous stage. Enter the repository path of your cloned template site - it should be something like `your-username/repository-name`.

### Set up the GitHub webhook

### Configure the editor link on your site

Go to the `_config.yml` file in your site's GitHub repository, and add the URL of your deployed Heroku app to the `votebot_url` setting. It will be the same as what you put in above for the GitHub application homepage, i.e. `https://your-unique-votebot-app-name.herokuapp.com`

### Enable the nightly update task
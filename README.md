[![Build status](https://github.com/openpolitics/groupthink/workflows/CI/badge.svg)](https://github.com/openpolitics/groupthink/actions) [![Test Coverage](https://api.codeclimate.com/v1/badges/9cccf0871769f93e2807/test_coverage)](https://codeclimate.com/github/openpolitics/groupthink/test_coverage) [![Maintainability](https://api.codeclimate.com/v1/badges/9cccf0871769f93e2807/maintainability)](https://codeclimate.com/github/openpolitics/groupthink/maintainability) [![Inline docs](http://inch-ci.org/github/openpolitics/groupthink.svg?branch=master)](http://inch-ci.org/github/openpolitics/groupthink)


# Groupthink

A collaborative writing platform built on top of GitHub, originally designed for open policymaking and manifesto writing.

It has two main functions:

1. Provide a user-friendly interface to make changes (using pull requests) to GitHub-hosted Jekyll websites, using Markdown.

2. Monitor discussion in those pull requests, and layer on a voting system to determine what should be merged in. Voting is done using special symbols in pull requests, which are counted by the app. Status is set using the GitHub commit status API.

The system was originally implemented for the collaborative manifesto project at https://openpolitics.org.uk/manifesto. The canonical instance of this app for that project is https://votebot.openpolitics.org.uk

## Usage

... to be written ...

### Voting rules

... to be written ...

## Get your own!

If you want to run your own open democratic platform, you can! This isn't a simple process yet, but we'll help you through as best we can...

Note that the style and headers of the deployed app will still match the [OpenPolitics Manifesto version](https://votebot.openpolitics.org.uk). A [change for that](https://github.com/openpolitics/groupthink/issues/42) will be coming soon.

### Set up a GitHub repository for your content

You can use Groupthink to edit any GitHub repository you like, but we've set up a template site using GitHub Pages and Jekyll to get you started.

[Click here to create your very own copy, ready to go.](https://github.com/openpolitics/template/fork)

Then visit the cloned repository's settings page, and:

* rename it to something more useful than `template`
* enable GitHub pages on the `master` branch

Your new site will be visible at `https://{{your-username}}.github.io/{{repository-name}}`. If you've set up a CNAME on your user site, the URL will be different, but you're advanced enough to work that out yourself.

### Create a GitHub API token

Visit the [Personal Access Tokens page](https://github.com/settings/tokens) on your GitHub account to create a token for accessing the API.

**Note:** you may want to create a new 'robot' GitHub account for this token. For example, the OpenPolitics Manifesto uses [openpolitics-bot](https://github.com/openpolitics-bot).

Generate a new token. You'll need to allow the following permissions:

* public_repo
* repo:status
* user:email
* write:repo_hook

Keep hold of the generated token - you'll need it in a minute.

### Create a GitHub OAuth application

Visit the [Developer applications page](https://github.com/settings/developers) on your GitHub account to set up user login via GitHub. Register a new application; in the homepage and callback URLs enter the URL of the application you are about to deploy. Yes, that's slightly tricky. It will be something like `https://your-unique-groupthink-app-name.herokuapp.com`. Make up the `your-unique-groupthink-app-name` part. The name of your project will probably do.

Again, keep hold of the client ID and secret. You'll need them in the next step.

**Note:** if you created the manifesto repository in a GitHub organisation, the OAuth application should be owned by the same organisation. If not, users in the organisation will not be able to create new proposals unless they manually grant access to the organisation when they log in.

### Deploy the code to Heroku

Hit this big deploy button here:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

Then, enter all the relevant details. Use the same app name you did in the step above, `your-unique-groupthink-app-name`. If it's taken, don't worry, you can go back and edit the GitHub application settings later.

Enter the personal access token, client ID, and secret from the previous stage. Enter the repository path of your cloned template site - it should be something like `your-username/repository-name`.

### Set up the GitHub webhook

Go back to the GitHub setting tab for your repository and click on `webhooks`, then `Add a webhook`.

Enter the Payload URL `https://your-unique-groupthink-app-name.herokuapp.com/webhook`, changing the root URL to be the one you're using for your deployed groupthink.

Leave the rest of the settings on default except for "which events would you like to trigger this webhook?". Select "Let me select individual events" and then choose:

* Issue comment
* Pull request

**Note:** *Pushes* is selected by default, so make sure you uncheck it.

Save the webhook. It will probably complain with the test payload, but should work for the real thing. [We'll fix this soon](https://github.com/openpolitics/groupthink/issues/44). [We might even be able to automate it](https://github.com/openpolitics/groupthink/issues/43).

### Configure the editor link on your site

Go to the `_config.yml` file in your site's GitHub repository, and add the URL of your deployed Heroku app to the `groupthink_url` setting. It will be the same as what you put in above for the GitHub application homepage, i.e. `https://your-unique-groupthink-app-name.herokuapp.com`

### Enable the nightly tasks

Visit the Heroku dashboard for your app, and on the "Resources" tab, choose the Heroku Scheduler. Add a new job, `rake nightly`, on a free dyno on a daily schedule. It's probably sensible to run it sometime in the small hours of the morning.

This task will run the following tasks, in this order:

 * `rake merge`: merges any proposals that have been passed
 * `rake close`: closes any proposals that are over the maximum age
 * `rake update`: reloads data from github, counts votes, and performs time checks.

Because `update` is run last, proposals will be marked as passed or dead, and closed or merged on the next run of the rake task. If run nightly, this gives 24 hours of grace before automatic actions are taken.

### Enable automatic deployment

If you want to keep your version of groupthink up to date with the latest changes, visit the Heroku dashboard for your app, and enable automatic deployment on the Deploy tab.

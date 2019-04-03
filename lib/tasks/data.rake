# frozen_string_literal: true

namespace :data do
  task migrate_stored_votes: :environment do
    # Migrate "disagree" to "block" first
    Interaction.all.each do |interaction|
      interaction.last_vote = "yes" if interaction.last_vote == "agree"
      interaction.last_vote = "no" if interaction.last_vote == "abstain"
      interaction.last_vote = "block" if interaction.last_vote == "disagree"
      interaction.save(validate: false)
    end
  end
end

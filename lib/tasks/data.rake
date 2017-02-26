namespace :data do
  
  task :migrate_stored_votes => :environment do
    # Migrate "disagree" to "block" first
    Interaction.all.each do |interaction|
      interaction.last_vote = "block" if interaction.last_vote == "disagree"
      interaction.save(validate: false)
    end
  end

end
RailsAdmin.config do |config|
  # == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  # == CancanCan ==
  config.authorize_with :cancancan

  # == PaperTrail ==
  config.audit_with :paper_trail, "User", "PaperTrail::Version"

  config.included_models = [ User, Proposal ]

  config.actions do
    dashboard
    index
    edit
    show_in_app
    delete

    # PaperTrail
    history_index
    history_show
  end
end

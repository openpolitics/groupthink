RailsAdmin.config do |config|

  # == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  # == CancanCan ==
  config.authorize_with :cancancan

  # == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  config.included_models = [ User, Proposal ]
  config.actions do
    dashboard
    index
    show
    edit
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end

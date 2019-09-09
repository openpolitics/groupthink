# frozen_string_literal: true

#
# Admin capability configuration for CanCanCan
#
class Ability
  include CanCan::Ability
  def initialize(user)
    return unless user && user.admin?
    can :access, :rails_admin
    can :manage, :all
  end
end

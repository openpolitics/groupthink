# frozen_string_literal: true

#
# Configuration for user admin interface
#
module UserAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      object_label_method do
        :login
      end
      list do
        field :avatar do
          pretty_value do
            bindings[:view].tag(:img, src: bindings[:object].avatar_url, height: "20px")
          end
        end
        field :login
        field :role
        field :author
        field :voter
      end
    end
  end
end

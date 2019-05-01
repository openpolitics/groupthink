# frozen_string_literal: true

# @!visibility private
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

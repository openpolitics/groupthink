# frozen_string_literal: true

Rules.add_source! Rails.root.join("config", "rules.yml").to_s
Rules.reload!

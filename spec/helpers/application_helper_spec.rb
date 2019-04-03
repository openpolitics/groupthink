# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe("#vote_icon") do
    {
      yes: "check",
      no: "times",
      block: "ban",
      abstention: "meh-o",
      participating: "comments-o",
    }.each_pair do |vote, icon|
      it("can create an icon for '#{vote}' votes") do
        html = helper.vote_icon(vote.to_s)
        expect(html).to eq("<i class=\"fa fa-#{icon}\"></i>")
      end
    end

    it("can create a sized voting icon") do
      expect(helper.vote_icon("yes", size: "2x")).to include("fa-2x")
    end
  end

  describe("#state_icon") do
    {
      waiting: "clock-o",
      blocked: "ban",
      rejected: "ban",
      dead: "ban",
      accepted: "check",
      passed: "check",
      agreed: "check",
    }.each_pair do |state, icon|
      it("can create an icon for the '#{state}' state") do
        html = helper.state_icon(state.to_s)
        expect(html).to eq("<i class=\"fa fa-#{icon}\"></i>")
      end
    end

    it("can create a sized state icon") do
      expect(helper.state_icon("waiting", size: "2x")).to include("fa-2x")
    end
  end
end

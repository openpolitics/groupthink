# frozen_string_literal: true

require "rails_helper"

# Specs in this file have access to a helper object that includes
# the ProposalsHelper. For example:
#
# describe ProposalsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe ProposalsHelper, type: :helper do
  context "when replacing emoji" do
    {
      ":thumbsup:" => "👍",
      ":thumbsdown:" => "👎",
      ":+1:" => "👍",
      ":-1:" => "👎",
      ":hand:" => "✋",
      ":smiley:" => "😃",
    }.each_pair do |input, output|
      it "#{input} with #{output}" do
        expect(helper.replace_emoji(input)).to eql output
      end
    end
  end

  context "when linking usernames" do
    it "at the start of a string" do
      input = "@hello there"
      output = "<a href='/users/hello'>@hello</a> there"
      expect(helper.link_usernames(input)).to eql output
    end

    it "in the middle of a string" do
      input = "well @hello there"
      output = "well <a href='/users/hello'>@hello</a> there"
      expect(helper.link_usernames(input)).to eql output
    end

    it "at the end of a string" do
      input = "well @hello"
      output = "well <a href='/users/hello'>@hello</a>"
      expect(helper.link_usernames(input)).to eql output
    end

    it "at the start of a paragraph tag" do
      input = "<p>@hello there</p>"
      output = "<p><a href='/users/hello'>@hello</a> there</p>"
      expect(helper.link_usernames(input)).to eql output
    end

    it "not in an email address" do
      input = "bob@example.com"
      output = "bob@example.com"
      expect(helper.link_usernames(input)).to eql output
    end
  end

  context "when linking proposals" do
    it "at the start of a string" do
      input = "#434 is relevant"
      output = "<a href='/proposals/434'>#434</a> is relevant"
      expect(helper.link_proposals(input)).to eql output
    end

    it "in the middle of a string" do
      input = "I think #434 is relevant"
      output = "I think <a href='/proposals/434'>#434</a> is relevant"
      expect(helper.link_proposals(input)).to eql output
    end

    it "at the end of a string" do
      input = "see #434"
      output = "see <a href='/proposals/434'>#434</a>"
      expect(helper.link_proposals(input)).to eql output
    end

    it "at the start of a paragraph tag" do
      input = "<p>#434 is relevant</p>"
      output = "<p><a href='/proposals/434'>#434</a> is relevant</p>"
      expect(helper.link_proposals(input)).to eql output
    end

    it "not in an HTML entity" do
      input = "&#434;"
      output = "&#434;"
      expect(helper.link_proposals(input)).to eql output
    end
  end
end

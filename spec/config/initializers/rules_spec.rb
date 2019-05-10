# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rules do
  around do |example|
    env = {
      YES_WEIGHT: "1",
      NO_WEIGHT: "-1",
      BLOCK_WEIGHT: "-10",
      PASS_THRESHOLD: "2",
      BLOCK_THRESHOLD: "-1",
      MIN_AGE: "7",
      MAX_AGE: "90"
    }
    ClimateControl.modify env do
      described_class.reload!
      example.run
    end
  end

  it "creates a global Rules object" do
    expect(described_class).to be_present
  end

  context "when loading voting rules from ENV" do
    it "loads 'yes' weight" do
      expect(described_class.yes_weight).to eq 1
    end

    it "loads 'no' weight" do
      expect(described_class.no_weight).to eq(-1)
    end

    it "loads 'block' weight" do
      expect(described_class.block_weight).to eq(-10)
    end

    it "loads pass threshold" do
      expect(described_class.pass_threshold).to eq 2
    end

    it "loads block threshold" do
      expect(described_class.block_threshold).to eq(-1)
    end

    it "loads minimum age" do
      expect(described_class.min_age).to eq 7
    end

    it "loads maximum age" do
      expect(described_class.max_age).to eq 90
    end
  end
end

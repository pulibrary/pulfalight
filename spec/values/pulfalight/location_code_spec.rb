# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pulfalight::LocationCode do
  subject(:location_code) { described_class.new(value) }
  let(:value) { "cotsen" }

  describe ".map" do
    let(:output) { described_class.map(value) }

    it "maps a code to a human-readable label" do
      expect(output).to eq("Firestone Library")
    end
  end

  describe ".registered?" do
    it "determines whether or not a code has a human-readable label" do
      expect(described_class.registered?(value)).to be true
      expect(described_class.registered?("foo")).to be false
    end
  end

  describe ".resolve" do
    let(:output) { described_class.resolve(value) }

    it "constructs a new LocationCode object and resolves the code" do
      expect(output).to eq("Firestone Library")
    end

    context "when an invalid configuration file is provided" do
      let(:config_file_path) do
        Rails.root.join("spec", "fixtures", "config", "location_codes_invalid.yml")
      end

      before do
        allow(Rails.logger).to receive(:error)
        allow(IO).to receive(:read).and_call_original
        allow(IO).to receive(:read).with(described_class.config_file_path.to_s).and_return(File.read(config_file_path))
        described_class.instance_variable_set(:@config_file, nil)
        described_class.instance_variable_set(:@config_erb, nil)
        described_class.instance_variable_set(:@config, nil)
      end

      after do
        described_class.instance_variable_set(:@config_file, nil)
        described_class.instance_variable_set(:@config_erb, nil)
        described_class.instance_variable_set(:@config, nil)
        allow(IO).to receive(:read).with(described_class.config_file_path.to_s).and_call_original
      end

      it "raises and logs an error" do
        expect { output }.to raise_error(SyntaxError, "#{described_class.config_file_path} was found, but could not be parsed with ERB. Please inspect the logs for more information.")
        error_message = Regexp.escape("#{described_class.config_file_path} was found, but could not be parsed with ERB.")
        expect(Rails.logger).to have_received(:error).with(/#{error_message}/)
      end
    end
  end

  describe "#value" do
    it "accesses the value of the code" do
      expect(location_code.value).to eq(value)
    end
  end

  describe "#url" do
    it "gets the url" do
      expect(location_code.url).to eq "https://library.princeton.edu/special-collections/visit-us"
    end
  end

  describe "#resolve" do
    it "provides a human-readable label for a location code" do
      expect(location_code.resolve).to eq("Firestone Library")
    end
  end

  describe "#to_s" do
    it "delegates to the human-readable label" do
      expect(location_code.to_s).to eq("Firestone Library")
    end
  end
end

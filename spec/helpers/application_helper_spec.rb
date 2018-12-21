
require 'rails_helper'

describe ApplicationHelper do

  describe "repository_thumbnail" do
    let(:repository) { instance_double(Arclight::Repository) }

    before do
      allow(repository).to receive(:name).and_return('Seeley G. Mudd Manuscript Library')
      allow(repository).to receive(:thumbnail_url).and_return('http://institution.edu/findingaids/thumbnail.png')
    end

    it 'generates the image markup for a configured repository thumbnail' do
      expect(helper.repository_thumbnail(repository)).to eq '<img alt="Seeley G. Mudd Manuscript Library" class="img-fluid" src="http://institution.edu/findingaids/thumbnail.png" />'
    end

    context 'when the repository does not have a thumbnail configured' do
      before do
        allow(repository).to receive(:thumbnail_url).and_return(nil)
      end

      it 'generates the image markup for the default repository thumbnail' do
        expect(helper.repository_thumbnail(repository)).to include "<img alt=\"Seeley G. Mudd Manuscript Library\" class=\"img-fluid\" src=\""
        expect(helper.repository_thumbnail(repository)).to match /\/assets\/logo\-.+?\.png/
      end
    end
  end
end

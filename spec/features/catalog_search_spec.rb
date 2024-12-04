# frozen_string_literal: true
require "rails_helper"

describe "catalog searches", type: :feature, js: true do
  context "when searching for a specific collection by ID" do
    before do
      visit "/?search_field=all_fields&q=WC127"
    end

    it "renders all collection extents on the collection show page" do
      expect(page).to have_text("1.5 linear feet")
      expect(page).to have_text("1 box")
    end
  end

  context "when searching for an unpublished collection", js: false do
    let(:id) { "C1545" }
    it "does not return it" do
      visit "/?search_field=all_fields&q=#{id}"
      expect(page).to have_content "No results found for your search"
    end
    it "doesn't return a show page" do
      visit "/catalog/#{id}"
      expect(page).to have_content "The page you were looking for doesn't exist."
    end
    it "doesn't normally return JSON" do
      visit "/catalog/#{id}.json"
      expect(page).to have_content "Not Found"
    end
    it "returns JSON if given an auth token" do
      stub_aspace_login
      stub_search_archive(id: id)
      visit "/catalog/#{id}.json?auth_token=#{Pulfalight.config['unpublished_auth_token']}"
      json = JSON.parse(page.body)
      expect(json["id"]).to eq id
      expect(json["title"]).to eq "James Daugherty Papers"
    end

    context "and the actual collection id contains a dot" do
      let(:id) { "C0744-02" }
      it "returns JSON if given an auth token" do
        stub_aspace_login
        stub_search_archive(id: id)
        visit "/catalog/#{id}.json?auth_token=#{Pulfalight.config['unpublished_auth_token']}"
        json = JSON.parse(page.body)
        expect(json["id"]).to eq "C0744.02"
        expect(json["title"]).to eq "Garrett Mesoamerican Manuscripts"
      end
    end

    context "and there's an error connecting to aspace" do
      it "logs the error, but still 404s" do
        allow(Aspace::Client).to receive(:new).and_raise(ArchivesSpace::ConnectionError)
        allow(Rails.logger).to receive(:error)

        visit "/catalog/#{id}.json?auth_token=#{Pulfalight.config['unpublished_auth_token']}"
        # expect { }.to raise_error ArchivesSpace::ConnectionError
        expect(Rails.logger).to have_received(:error).with("ArchivesSpace::ConnectionError")
        expect(page).to have_content "Not Found"
      end
    end
  end

  context "when searching for an unpublished component", js: false do
    let(:id) { "C0140_c88205-61643" }
    it "does not return it" do
      visit "/?search_field=all_fields&q=#{id}"
      expect(page).to have_content "No results found for your search"
    end
    it "doesn't return a show page" do
      visit "/catalog/#{id}"
      expect(page).to have_content "The page you were looking for doesn't exist."
    end
    it "doesn't normally return JSON" do
      visit "/catalog/#{id}.json"
      expect(page).to have_content "Not Found"
    end
    it "returns JSON if given an auth token" do
      stub_aspace_login
      stub_search_archive(id: id)
      visit "/catalog/#{id}.json?auth_token=#{Pulfalight.config['unpublished_auth_token']}"
      json = JSON.parse(page.body)
      expect(json["id"]).to eq id
      expect(json["title"]).to eq "Photograph Album of a Cruise in Mediterranean, 1934 March-April"
    end
  end

  context "when searching for a nonexistent collection", js: false do
    let(:id) { "bad_id" }
    it "404s even if given an auth token" do
      stub_aspace_login
      stub_search_archive(id: id)
      visit "/catalog/#{id}.json?auth_token=#{Pulfalight.config['unpublished_auth_token']}"
      expect(page.status_code).to eq 404
    end
  end

  context "when searching for a specific collection by title", js: false do
    context "david lilienthal papers" do
      before do
        visit "/?search_field=all_fields&q=david+e.+lilienthal+papers%2C+1900-1981"
      end
      it "renders all collection extents in the collection search results" do
        expect(page).to have_text("4 items")
        expect(page).to have_text("632 boxes")
      end
      it "renders the call number/title" do
        expect(page).to have_content "MC148"
        within first("h3") do
          expect(page).to have_content "David E. Lilienthal Papers"
        end
      end
      it "returns all components in that collection", js: false do
        visit "/?search_field=all_fields&group=false&q=Walter Dundas Bathurst Papers"
        expect(page).to have_text("17 entries")
      end
    end

    context "and the collection contains restricted materials", js: true do
      it "shows a restricted badge in the search results which is not a link" do
        visit "/?search_field=all_fields&group=false&q=Toni Morrison Papers"
        expect(page.find(:element, 'data-document-id': /C1491_c5210/).text.match?(/Restricted Content/)).to eq true
        expect(page.find(:element, 'data-document-id': /C1491_c1902/).text.match?(/Restricted Content/)).to eq false
        expect(page.find(:element, 'data-document-id': /C1491_c1902/).find(:element, 'class': /document-access review/)).to be_instance_of Capybara::Node::Element
        expect(page).to have_content "Restricted Content"
        expect(page).not_to have_link "Restrictions may apply."
        expect(page).not_to have_content "See Access Note."
        # the badge in Grouped by collection is also not a link.
        click_on("Grouped by collection")
        expect(page).not_to have_link "Restrictions may apply."
      end
    end
  end

  context "when displaying grouped results", js: false do
    it "renders components with their descriptions" do
      visit "/?search_field=all_fields&group=true&q=david+e.+lilienthal+papers%2C+1900-1981"

      expect(page).to have_content "mostly professional correspondence to and from Lilienthal"
    end
  end

  context "when searching using the search form" do
    it "returns search results grouped by collection as a default" do
      visit "/?q=&search_field=all_fields"
      find("#search").click
      expect(page).to have_current_path(/group=true/)
    end

    context "when faceting by collection" do
      it "does not return results grouped by collection" do
        visit "/?f%5Bcollection_sim%5D%5B%5D=Barr+Ferree+collection%2C+1880-1929&group=true"
        expect(page).not_to have_selector(".al-grouped-title-bar")
      end
    end
  end

  context "when searching by date" do
    it "provides a helpful message if the date query is invalid" do
      visit "/?utf8=%E2%9C%93&group=true&search_field=all_fields&q=&range%5Bdate_range_sim%5D%5Bbegin%5D=1900&range%5Bdate_range_sim%5D%5Bend%5D=1800&commit=Limit"
      expect(page).to have_text("The start year must be before the end year.")
    end
  end

  describe "online content badges" do
    context "when displaying all results", js: false do
      it "renders results with an online content badges" do
        visit "/?q=Harold+B.+Hoskins+Papers&search_field=all_fields"

        expect(page).to have_content "HAS ONLINE CONTENT"
      end
    end

    context "when displaying grouped results", js: false do
      it "renders results with an online content badges" do
        visit "/??group=true&q=Harold+B.+Hoskins+Papers&search_field=all_fields"

        expect(page).to have_content "SOME ONLINE CONTENT"
      end
    end
  end

  context "when searching within a collection", js: false do
    it "renders breadcrumbs" do
      visit "/catalog?f%5Bcollection_sim%5D%5B%5D=Margaret+K.+McElderry+Papers%2C+1900&q=Cats&search_field=all_fields"
      expect(page).to have_link "Joan Phipson"
    end
  end
end

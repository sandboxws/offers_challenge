require 'spec_helper'

describe OffersController do
  render_views
  describe "GET #index" do
    it "responds successfully with an HTTP 200 status code" do
      get :index
      expect(response).to be_success
      expect(response.status).to eq(200)
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template("index")
    end

    it "renders the offers form" do
      get :index
      expect(response.body).to have_css("form#offers_form")
    end

    it "fills the offers form and displays no offers" do
      visit '/'
      within("#offers_form") do
        fill_in 'uid', with: 'player1'
        fill_in 'pub0', with: 'campaign2'
        fill_in 'page', with: '1'
      end
      url = Offer.get_offers_api_url 'player1', 'campaign2', 1
      stub_request(:get, url).to_return(body: "{\"code\": \"NO_CONTENT\"}")
      click_button 'Display Offers'
      expect(page).to have_content 'Latest Offers'
      expect(page).to have_css '.no_offers'
    end

    it "fills the offers form and displays one offer" do
      visit '/'
      within("#offers_form") do
        fill_in 'uid', with: 'player1'
        fill_in 'pub0', with: 'campaign2'
        fill_in 'page', with: '1'
      end
      url = Offer.get_offers_api_url 'player1', 'campaign2', 1
      stub_request(:get, url).to_return(body: IO.read("#{Rails.root}/spec/mock/offers.json"))
      click_button 'Display Offers'
      expect(page).to have_content 'Latest Offers'
      expect(page).to have_css '.offers'
      expect(page).to have_css '.offers .offer', count: 1
    end
  end
end
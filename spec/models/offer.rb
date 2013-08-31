require 'spec_helper'

describe Offer do
  context 'class methods' do
    before :all do
      @uid = 'player1'
      @pub0 = 'campaign2'
      @page = 1
      @params = Offer.get_params(@uid, @pub0, @page)
    end

    it "returns required params sorted" do
      @params.keys.first.should eq :appid
      @params.keys.last.should eq  :uid
    end

    it "returns required params" do
      @params[:appid].should eq AppBox.appid
      @params[:uid].should eq 'player1'
      @params[:locale].should eq AppBox.locale
      @params[:device_id].should eq AppBox.device_id
      @params[:timestamp].should eq Time.now.to_i
    end

    it "returns valid SHA1 hashkey" do
      Offer.get_hashkey('foo=bar&hello=world').should eq Digest::SHA1.hexdigest "foo=bar&hello=world&#{AppBox.api_key}"
    end

    it "returns params as string with the hashkey appended" do
      hashkey = Digest::SHA1.hexdigest "foo=bar&#{AppBox.api_key}"
      params_str = "foo=bar&hashkey=#{hashkey}"
      Offer.get_params_str([['foo', 'bar']]).should eq params_str
    end

    it "returns valid offers api url" do
      url = Offer.get_offers_api_url('player1', 'campaign2', 1)
      url.should match 'api.sponsorpay.com/feed/v1/offers.json'
      url.should match 'appid='
      url.should match 'hashkey='
    end
  end

  context 'get offers' do

    it "returns no content response" do
      url = Offer.get_offers_api_url 'player1', 'campaign2', 1
      stub_request(:get, url).to_return(body: "{\"code\": \"NO_CONTENT\"}")
      result = Offer.get_offers('player1', 'campaign2', 1)
      result[:code].should eq 'NO_CONTENT'
      result[:offers].should be_empty
    end

    it "returns invalid page error" do
      WebMock.disable!
      expect { Offer.get_offers('player1', 'campaign2', 2) }.to raise_error('ERROR_INVALID_PAGE')
    end

    it "returns invalid uid error" do
      WebMock.disable!
      expect { Offer.get_offers(nil, 'campaign2', 2) }.to raise_error('ERROR_INVALID_UID')
    end

    it "returns valid response including offers" do
      url = Offer.get_offers_api_url 'player1', 'campaign2', 1
      stub_request(:get, url).to_return(body: IO.read("#{Rails.root}/spec/mock/offers.json"))
      result = Offer.get_offers('player1', 'campaign2', 1)

      result[:code].should eq 'OK'
      result[:information][:appid].should eq AppBox.appid
    end

    it "returns only one offer" do
      url = Offer.get_offers_api_url 'player1', 'campaign2', 1
      stub_request(:get, url).to_return(body: IO.read("#{Rails.root}/spec/mock/offers.json"))
      result = Offer.get_offers('player1', 'campaign2', 1)

      result[:offers].size.should eq 1
      result[:count].should eq '1'
    end
  end
end
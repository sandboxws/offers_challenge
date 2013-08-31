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

    it "validates response signature and returns true" do
      body = '{"foo": "bar"}'
      header = { 'X-Sponsorpay-Response-Signature' =>  Digest::SHA1.hexdigest("#{body}#{AppBox.api_key}") }
      Offer.validate_response_signature(header, body).should eq true
    end

    it "validates response signature and raises an error" do
      body = '{"foo": "bar"}'
      header = { 'X-Sponsorpay-Response-Signature' =>  Digest::SHA1.hexdigest("#{AppBox.api_key}") }
      expect { Offer.validate_response_signature(header, body) }.to raise_error('ERROR_INVALID_RESPONSE_SIGNATURE')
    end
  end

  context 'get offers' do

    it "returns no content response" do
      url = Offer.get_offers_api_url 'player1', 'campaign2', 1
      body = "{\"code\": \"NO_CONTENT\"}"
      stub_request(:get, url).to_return(
        body: body,
        headers: { 'X-Sponsorpay-Response-Signature' =>  Digest::SHA1.hexdigest("#{body}#{AppBox.api_key}") }
      )
      result = Offer.get_offers('player1', 'campaign2', 1)
      result[:code].should eq 'NO_CONTENT'
      result[:offers].should be_empty
    end

    it "returns invalid page error" do
      url = Offer.get_offers_api_url 'player1', 'campaign2', 2
      stub_request(:get, url).to_raise 'ERROR_INVALID_PAGE'
      expect { Offer.get_offers('player1', 'campaign2', 2) }.to raise_error('ERROR_INVALID_PAGE')
    end

    it "returns invalid uid error" do
      url = Offer.get_offers_api_url nil, 'campaign2', 1
      stub_request(:get, url).to_raise 'ERROR_INVALID_UID'
      expect { Offer.get_offers(nil, 'campaign2', 1) }.to raise_error('ERROR_INVALID_UID')
    end

    it "returns valid response including offers" do
      url = Offer.get_offers_api_url 'player1', 'campaign2', 1
      body = IO.read("#{Rails.root}/spec/mock/offers.json")
      stub_request(:get, url).to_return(
        body: body,
        headers: { 'X-Sponsorpay-Response-Signature' =>  Digest::SHA1.hexdigest("#{body}#{AppBox.api_key}") }
      )
      result = Offer.get_offers('player1', 'campaign2', 1)

      result[:code].should eq 'OK'
      result[:information][:appid].should eq AppBox.appid
    end

    it "returns only one offer" do
      url = Offer.get_offers_api_url 'player1', 'campaign2', 1
      body = IO.read("#{Rails.root}/spec/mock/offers.json")
      stub_request(:get, url).to_return(
        body: body,
        headers: { 'X-Sponsorpay-Response-Signature' =>  Digest::SHA1.hexdigest("#{body}#{AppBox.api_key}") }
      )
      result = Offer.get_offers('player1', 'campaign2', 1)

      result[:offers].size.should eq 1
      result[:count].should eq '1'
    end
  end
end
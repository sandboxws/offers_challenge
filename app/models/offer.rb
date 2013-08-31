class Offer
  ERROR_CODES = [
    'ERROR_INVALID_PAGE',
    'ERROR_INVALID_APPID',
    'ERROR_INVALID_UID',
    'ERROR_INVALID_HASHKEY',
    'ERROR_INVALID_DEVICE_ID',
    'ERROR_INVALID_IP',
    'ERROR_INVALID_TIMESTAMP',
    'ERROR_INVALID_LOCALE',
    'ERROR_INVALID_ANDROID_ID',
    'ERROR_INVALID_CATEGORY',
    'ERROR_INTERNAL_SERVER_ERROR'
  ]

  def self.get_offers(uid, pub0, page)
    url = get_offers_api_url uid, pub0, page
    response = HTTParty.get url

    body = MultiJson.load response.body, symbolize_keys: true
    code = body[:code]

    if ERROR_CODES.include?(code)
      raise body[:code]
    else
      validate_response_signature(response.header, response.body)
      if code == 'OK'
        body
      elsif code == 'NO_CONTENT'
        {
          offers: [],
          code: code
        }
      end
    end
  end

  private
  def self.get_params(uid, pub0, page)
    params = {
      appid: AppBox.appid,
      uid: uid,
      ip: AppBox.ip,
      locale: AppBox.locale,
      device_id: AppBox.device_id,
      ps_time: 1377612731, # hard coded for testing
      pub0: pub0,
      page: page,
      timestamp: Time.now.to_i,
      offer_types: AppBox.offer_types
    }

    params = Hash[params.sort]
  end

  def self.get_params_str(params)
    params_str = params.map {|k,v| "#{k}=#{v}" }.join('&')
    hashkey = get_hashkey(params_str)
    params_str += "&hashkey=#{hashkey}"
  end

  def self.get_hashkey(params_str)
    hashkey = Digest::SHA1.hexdigest "#{params_str}&#{AppBox.api_key}"
  end

  def self.get_offers_api_url(uid, pub0, page)
    params = get_params uid, pub0, page
    params_str = get_params_str params
    "http://api.sponsorpay.com/feed/v1/offers.json?#{params_str}"
  end

  def self.validate_response_signature(header, body)
    correct_signature = Digest::SHA1.hexdigest body + "#{AppBox.api_key}"
    returned_signature = header['X-Sponsorpay-Response-Signature']
    raise 'ERROR_INVALID_RESPONSE_SIGNATURE'if correct_signature != returned_signature
    true
  end
end
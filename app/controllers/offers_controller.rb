class OffersController < ApplicationController
  def index
  end

  def results
    @result = Offer.get_offers(params[:uid], params[:pub0], params[:page])
    @offers = @result[:offers]
  end
end
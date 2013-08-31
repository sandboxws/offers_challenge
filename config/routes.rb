OffersChallenge::Application.routes.draw do
  match '/offers/results' => 'offers#results', via: :post
  root to: 'offers#index'
end

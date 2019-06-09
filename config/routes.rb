Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
post '/yohane/webhook', to:'yohane#webhook'
post '/twitter_subscribe', to:'yohane#twitter_subscribe'
end

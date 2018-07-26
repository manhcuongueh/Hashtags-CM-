Rails.application.routes.draw do
  root 'users#new'
  get  'index' => 'users#index'
  post 'index' => 'users#create'
  post '' => 'users#delete'
  get  'api/user' => 'api#user_json'
  get  'api/hashtag' => 'api#hashtag_json'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end

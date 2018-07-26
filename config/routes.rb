Rails.application.routes.draw do
  root 'users#new'
  get  'index' => 'users#index'
  post 'index' => 'users#create'
  post '' => 'users#delete'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end

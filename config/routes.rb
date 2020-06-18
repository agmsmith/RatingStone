# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  root 'static_pages#home'
  get '/about', to: 'static_pages#about'
  get '/contact', to: 'static_pages#contact'
  get '/help', to: 'static_pages#help'
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  get '/logout', to: 'sessions#destroy' # For older browsers without Javascript.
  get '/signup', to: 'users#new'

  resources :users do
    member do
      get :following, :followers
    end
  end
  resources :account_activations, only: [:edit]
  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :microposts, only: [:create, :destroy]
  resources :ledger_posts, except: [:new]
  # Note can't use "/ledger_posts/:id" since that confuses the CSRF token
  # validation because that combines the action with the posting method to
  # generate the token.  So we use a slightly different action name in the URL.
  post '/ledger_posts_undelete/:id', to: 'ledger_posts#undelete',
    as: :ledger_post_undelete
  resources :relationships, only: [:create, :destroy]
end


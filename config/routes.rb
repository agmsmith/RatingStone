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
  resources :relationships, only: [:create, :destroy]

  # The usual actions for displaying/editing posts, plus a RESTful undelete.
  resources :ledger_posts do
    member do
      post 'undelete'
    end
  end

  # Low level interface for debugging ledger objects in general.
  resources :ledger_objects, only: [:index, :show, :edit, :update, :destroy] do
    member do
      post 'undelete'
    end
  end

  # Low level interface for debugging link objects in general.
  resources :link_objects, only: [:index, :show, :edit, :update, :destroy] do
    member do
      post 'undelete'
      post 'approve'
      post 'unapprove'
    end
  end

  # Clipboard for saving objects to use later.
  resources :clips, only: [:new, :index, :edit, :update, :destroy]
  post '/clip_ledger/:id', to: 'clips#create_ledger'
  post '/clip_link/:id', to: 'clips#create_link'
end


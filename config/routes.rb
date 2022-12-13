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
  get '/wordcounter', to: 'word_counter#update'
  post '/wordcounter', to: 'word_counter#update'

  resources :users
  resources :account_activations, only: [:edit]
  resources :password_resets, only: [:new, :create, :edit, :update]

  # Generic ledger_base actions, subclasses use it for destroy and undelete.
  resources :ledger_bases, only: [:index, :show, :destroy] do
    member do
      post 'undelete'
    end
  end

  # The usual actions for displaying/editing posts, plus reply and quote.  Also
  # can use ledger_bases API since LedgerPost is a subclass of LedgerBase.
  resources :ledger_posts,
   only: [:new, :create, :index, :show, :edit, :update] do
    member do
      get 'reply' # Make a new reply to a given post.
      get 'replies' # List all replies to a given post.
      get 'quote' # Make a new post quoting a given post.
      get 'quotes' # List all posts quoting a given post.
    end
  end
  patch '/ledger_posts', to: 'ledger_posts#update' # For update without an ID.

  # The usual actions for displaying/editing groups.
  resources :ledger_groups, only: [:new, :create, :index, :show, :edit, :update]

  # Low level interface for debugging generic link objects.
  resources :link_bases, only: [:index, :show, :destroy] do
    member do
      post 'undelete'
      post 'approve'
      post 'unapprove'
    end
  end

  # For LinkOpinion and LinkMetaOpinion (when field :number1 is defined), so
  # you can create a new opinion record and edit it before submitting.
  # Subclass of LinkBase, so it inherits actions from :link_bases.
  resources :link_opinions, only: [:index, :show, :new, :create, :destroy] do
    member do
      post 'undelete'
      post 'approve'
      post 'unapprove'
    end
  end
end


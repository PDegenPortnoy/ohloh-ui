Rails.application.routes.draw do
  root 'home#index'

  resources :api_keys, only: :index
  resources :domain_blacklists, except: :show

  resources :accounts, except: [:index, :show, :new, :create, :edit, :update, :delete] do
    resources :api_keys, constraints: { format: :html }, except: :show
    member do
      get :settings
    end
    resources :authorization
  end
  
  get '/oauth/test_request', to: 'authorization#test_request', as: :test_request
  get '/oauth/access_token', to: 'authorization#access_token', as: :access_token
  match '/oauth/request_token', to: 'authorization#request_token', as: :request_token, via: [:get, :post]
  get '/oauth/authorize', to: 'authorization#authorize', as: :authorize

  get 'coverage' => 'coverage#index'

  # The priority is based upon order of creation: first created -> highest
  # priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically)
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end

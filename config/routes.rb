require 'sidekiq/web'

GitReports::Application.routes.draw do
  # Error pages.
  %w[404 422 500].each do |code|
    match code, to: "errors#error_#{code}", via: :all
  end

  # Authentication routes
  get '/login', to: 'authentications#login', as: 'login'
  get '/github_callback', to: 'authentications#callback'
  get '/logout', to: 'authentications#logout', as: 'logout'
  get '/login_rate_limited', to: 'authentications#login_rate_limited', as: 'login_rate_limited'

  # Repository routes
  get '/profile', to: 'repositories#index', as: 'profile'
  scope :issue do
    get ':username/:repositoryname', to: 'repositories#repository', as: 'repository_public', repositoryname: %r{[^\/]+}
    post ':username/:repositoryname', to: 'repositories#submit', repositoryname: %r{[^\/]+}
    get ':username/:repositoryname/submitted', to: 'repositories#submitted', as: 'submitted', repositoryname: %r{[^\/]+}
  end

  resources :repositories, only: %i[show edit update] do
    post 'activate'
    post 'deactivate'
  end

  get '/load_status', to: 'repositories#load_status'

  # Sidekiq monitoring
  constraints ->(request) { User.find_by(id: request.session[:user_id])&.is_admin } do
    mount Sidekiq::Web => '/admin/sidekiq'
  end
end

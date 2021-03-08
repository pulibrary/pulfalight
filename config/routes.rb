# frozen_string_literal: true
Rails.application.routes.draw do
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  mount Blacklight::Engine => "/"
  mount Arclight::Engine => "/"

  root to: "catalog#index"
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: "catalog", path: "/catalog", controller: "catalog" do
    concerns :searchable
    concerns :range_searchable
  end
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }, skip: [:passwords, :registration]
  devise_scope :user do
    delete "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
    get "users/auth/cas", to: "users/omniauth_authorize#passthru", defaults: { provider: :cas }, as: "new_user_session"
  end
  concern :exportable, Blacklight::Routes::Exportable.new

  require "sidekiq/web"
  authenticate :user do
    mount Sidekiq::Web => "/sidekiq"
  end

  resources :solr_documents, only: [:show], path: "/catalog", controller: "catalog" do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete "clear"
    end
  end

  # Redirect requests in the form of legacy URL syntax to their new location.
  # Keep the entire eadid as passed, even if it contains dots. Replace the dots
  # with dashes in the redirect.
  get "/collections/:eadid/:componentid", constraints: { eadid: /([^\/])+?/ }, to: redirect { |params, _request|
    "/catalog/#{params[:eadid].tr('.', '-')}_#{params[:componentid]}"
  }

  get "/collections/:eadid", constraints: { eadid: /([^\/])+?/ }, format: /json|xml|html/, to: redirect { |params, _request|
    "/catalog/#{params[:eadid].tr('.', '-')}"
  }

  get "/toc", to: "toc#toc", as: "toc"
  get "/toc/:node/child_table", to: "toc#child_table", as: "toc_child_table"
  get "/hours", to: "hours#hours"
  get "/research_help", to: "about#research_help"
  get "/search_tips", to: "about#search_tips"
  get "/faq", to: "about#faq"
  get "/av_materials", to: "about#av_materials"
  get "/requesting_materials", to: "about#requesting_materials"
  get "/research_account", to: "about#research_account"
  get "/archival_language", to: "about#archival_language"
  post "/contact/suggest", to: "contact#suggest"
  post "/contact/question", to: "contact#question"
end

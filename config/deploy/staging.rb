# frozen_string_literal: true
set :rails_env, "staging"

server "pulfalight-staging1", user: "deploy", roles: %w[app db web worker]

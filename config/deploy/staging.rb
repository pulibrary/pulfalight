# frozen_string_literal: true
set :rails_env, "staging"

server "pulfalight-staging1.princeton.edu", user: "deploy", roles: %w[app db web worker]
server "pulfalight-staging2.princeton.edu", user: "deploy", roles: %w[app web worker]

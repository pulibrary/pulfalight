# frozen_string_literal: true
set :rails_env, "qa"

server "pulfalight-qa-web-1", user: "deploy", roles: %w[app db web]
server "pulfalight-qa-worker-1", user: "deploy", roles: %w[app worker]

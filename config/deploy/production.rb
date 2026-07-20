# frozen_string_literal: true
set :rails_env, "production"

server "pulfalight-jammy-prod1.princeton.edu", user: "deploy", roles: %w[app db web production_db]
server "pulfalight-jammy-prod2.princeton.edu", user: "deploy", roles: %w[app web]
server "pulfalight-prod-worker1.princeton.edu", user: "deploy", roles: %w[app worker]

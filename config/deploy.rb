# frozen_string_literal: true
# config valid for current version and patch releases of Capistrano
lock "~> 3.11"

set :application, "pulfalight"
set :repo_url, "https://github.com/pulibrary/pulfalight.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :branch, ENV["BRANCH"] || "main"

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"
set :deploy_to, "/opt/pulfalight"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
set :linked_dirs, fetch(:linked_dirs, []).push("log", "vendor/bundle", "public/uploads")

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

desc "Write SHA of current deploy to /version.txt"
task :write_version do
  on roles(:app), in: :sequence do
    within repo_path do
      execute :tail, "-n1 ../revisions.log > #{release_path}/public/version.txt"
    end
  end
end
after 'deploy:log_revision', 'write_version'

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

set :pulfa_dir_path, fetch(:pulfa_dir_path, "/var/opt/pulfa")
set :pulfa_collections, fetch(:pulfa_collections, %w[cotsen ea eng ga lae mss mudd rarebooks])

namespace :sidekiq do
  task :quiet do
    on roles(:worker) do
      puts capture("kill -USR1 $(sudo initctl status pulfalight-workers | grep /running | awk '{print $NF}') || :")
    end
  end
  task :restart do
    on roles(:worker) do
      execute :sudo, :service, "pulfalight-workers", :restart
    end
  end
end

task :robots_txt do
  on roles(:app) do
    within release_path do
      execute :rake, "pulfalight:robots_txt"
    end
  end
end

namespace :application do
  # You can/ should apply this command to a single host
  # cap --hosts=pulfalight-staging1.princeton.edu staging application:remove_from_nginx
  desc "Marks the server(s) to be removed from the loadbalancer"
  task :remove_from_nginx do
    count = 0
    on roles(:app) do
      count += 1
    end
    if count > (roles(:app).length / 2)
      raise "You must run this command on no more than half the servers utilizing the --hosts= switch"
    end
    on roles(:app) do
      within release_path do
        execute :touch, "public/remove-from-nginx"
      end
    end
  end

  # You can/ should apply this command to a single host
  # cap --hosts=pulfalight-staging1.princeton.edu staging application:serve_from_nginx
  desc "Marks the server(s) to be added back to the loadbalancer"
  task :serve_from_nginx do
    on roles(:app) do
      within release_path do
        execute :rm, "-f public/remove-from-nginx"
      end
    end
  end
end

namespace :deploy do
  desc "Generate the crontab tasks using Whenever"
  task :whenever do
    on roles(:db) do |host|
      within release_path do
        execute("cd #{release_path} && bundle exec whenever --update-crontab #{fetch :application} --set environment=#{fetch :rails_env, fetch(:stage, 'production')} --user=deploy --roles=#{host.roles_array.join(',')}")
      end
    end
  end
end

after "deploy:reverted", "sidekiq:restart"
after "deploy:starting", "sidekiq:quiet"
after "deploy:published", "sidekiq:restart"
after "deploy:published", "robots_txt"
before "deploy:assets:precompile", "deploy:whenever"

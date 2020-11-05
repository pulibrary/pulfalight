# config valid for current version and patch releases of Capistrano
lock "~> 3.11"

set :application, "pulfalight"
set :repo_url, "https://github.com/pulibrary/pulfalight.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :branch, ENV["BRANCH"] || "master"

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

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

set :pulfa_dir_path, fetch(:pulfa_dir_path, '/var/opt/pulfa')
set :pulfa_collections, fetch(:pulfa_collections, %w{cotsen ea eng ga lae mss mudd rarebooks})

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
      execute :rake, 'pulfalight:robots_txt'
    end
  end
end

after 'deploy:reverted', 'sidekiq:restart'
after 'deploy:starting', 'sidekiq:quiet'
after 'deploy:published', 'sidekiq:restart'

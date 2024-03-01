# frozen_string_literal: true
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :job_template, "bash -l -c 'export PATH=\"/usr/local/bin/:$PATH\" && :job'"
job_type :logging_rake, "cd :path && :environment_variable=:environment bundle exec rake :task :output"

# We've disabled DAO synchronization until Pulfalight can handle this.
every :hour, roles: [:production_db] do
  rake "pulfalight:indexing:incremental"
end

every 1.day, at: "10:00pm", roles: [:db] do
  rake "blacklight:delete_old_searches"
end

every 1.day, at: "10:30pm", roles: [:db] do
  rake "devise_guests:delete_old_guest_users"
end

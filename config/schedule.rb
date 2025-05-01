# frozen_string_literal: true
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :job_template, "bash -l -c 'export PATH=\"/usr/local/bin/:$PATH\" && :job'"
job_type :logging_rake, "cd :path && :environment_variable=:environment bundle exec rake :task :output"

# since the full index runs at 10 PM, run the incremental between 9am and 9pm
every "0 #{(9..21).map(&:to_s).join(',')} * * *", roles: [:production_db] do
  rake "pulfalight:indexing:incremental DEFAULT_LOGGER=true"
end

# incremental indexing sometimes misses updated records and we're not sure why.
# This is a stopgap so that if nothing else we know we can expect the updates to
# show by the next day.
every :day, at: "10:00 PM", roles: [:production_db] do
  rake "pulfalight:indexing:full DEFAULT_LOGGER=true"
end

every 1.day, at: "10:00pm", roles: [:db] do
  logging_rake "blacklight:delete_old_searches", output: { error: "/tmp/guest_searches.log", standard: "/tmp/guest_searches.log" }
end

every 1.day, at: "10:30pm", roles: [:db] do
  logging_rake "devise_guests:delete_old_guest_users", output: { error: "/tmp/clean_guest_users.log", standard: "/tmp/clean_guest_users.log" }
end

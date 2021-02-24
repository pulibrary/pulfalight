# frozen_string_literal: true
namespace :pulfalight do
  desc "Installs Pulfalight access key into .env via lastpass."
  task setup_keys: :environment do
    content = JSON.parse(`lpass show Shared-ITIMS-Passwords/pulfa/aspace.princeton.edu -j`).first
    File.open(".env", "w") do |f|
      f.puts "ASPACE_USER=#{content['username']}"
      f.puts "ASPACE_PASSWORD=#{content['password']}"
    end
    puts "Generated .env file"
  end
end

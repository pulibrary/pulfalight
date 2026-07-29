# frozen_string_literal: true
desc "Installs Pulfalight access key into .env via lastpass."
task setup_keys: :environment do
  content = JSON.parse(`lpass show Shared-ITIMS-Passwords/pulfa/aspace.princeton.edu -j`).first
  entra_content = JSON.parse(`lpass show Shared-ITIMS-Passwords/pulfalight/Pulfalight-Entra-Dev -j`).first
  File.open(".env", "w") do |f|
    f.puts "ASPACE_USER=#{content['username']}"
    f.puts "ASPACE_PASSWORD=#{content['password']}"
    f.puts "ENTRA_CLIENT_ID=#{entra_content['username']}"
    f.puts "ENTRA_CLIENT_SECRET=#{entra_content['password']}"
  end
  puts "Generated .env file"
end

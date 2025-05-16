# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Health Check", type: :request do
  describe "GET /health" do
    it "has a health check" do
      stub_aspace_login
      allow(Net::SMTP).to receive(:new).and_return(instance_double(Net::SMTP, "open_timeout=": nil, start: true))
      # stub the number of processes since sidekiq doesn't run in test
      allow(Sidekiq::Stats).to receive(:new).and_return(instance_double(Sidekiq::Stats, processes_size: 1))
      get "/health.json"
      expect(response).to be_successful
    end

    it "has a success response even if there are failures to non-critical services (e.g smtp)" do
      stub_aspace_login
      SmtpStatus.next_check_timestamp = 0
      get "/health.json"

      expect(response).to be_successful
    end

    it "errors when it can't contact the SMTP server when the provider is included" do
      SmtpStatus.next_check_timestamp = 0
      get "/health.json?providers[]=smtpstatus"

      expect(response).not_to be_successful
    end

    it "errors when there's a failure to a critical service (e.g. db)" do
      allow_any_instance_of(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter).to receive(:execute) do |instance|
        raise StandardError if database.blank? || instance.pool.db_config.name == database.to_s
      end
      stub_aspace_login

      get "/health.json"

      expect(response).not_to be_successful
      expect(response.status).to eq 503
    end

    it "caches a success on SMTP and doesn't call it twice in a short window" do
      SmtpStatus.next_check_timestamp = 0
      smtp_double = instance_double(Net::SMTP)
      allow(Net::SMTP).to receive(:new).and_return(smtp_double)
      allow(smtp_double).to receive(:open_timeout=)
      allow(smtp_double).to receive(:start)

      get "/health.json?providers[]=smtpstatus"
      expect(response).to be_successful
      get "/health.json?providers[]=smtpstatus"

      expect(Net::SMTP).to have_received(:new).exactly(1).times
    end
  end
end

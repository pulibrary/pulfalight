# frozen_string_literal: true

namespace :performance do
  require "ruby-prof"
  task reindex_profile: :environment do
    aspace_client = Aspace::Client.new
    # Force cache
    aspace_client.get_resource_description_xml(resource_descriptions_uri: "repositories/3/resource_descriptions/1777", cached: false)
    result = RubyProf.profile do
      AspaceIndexJob.perform_now(resource_descriptions_uri: "repositories/3/resource_descriptions/1777", repository_id: "publicpolicy", soft: true)
    end
    printer = RubyProf::CallStackPrinter.new(result)
    printer.print(File.open("tmp/output.html", "w"))
  end
  task reindex_benchmark: :environment do
    require "benchmark/ips"
    Benchmark.ips do |x|
      x.report("traject index") do
        AspaceIndexJob.perform_now(resource_descriptions_uri: "repositories/3/resource_descriptions/1777", repository_id: "publicpolicy", soft: true)
      end
    end
  end
rescue LoadError
end

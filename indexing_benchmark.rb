# frozen_string_literal: true

indexer = Traject::Indexer::NokogiriIndexer.new.tap do |i|
  i.load_config_file(Rails.root.join("lib", "plantain", "traject", "ead2_config.rb"))
end

Benchmark.ips do |x|
  x.report("MC057 Traject") do
    fixture_path = Rails.root.join("mega_parser", "test", "fixtures", "a0011.xml")
    fixture_file = File.read(fixture_path)
    nokogiri_reader = Arclight::Traject::NokogiriNamespacelessReader.new(fixture_file.to_s, indexer.settings)
    record = nokogiri_reader.to_a.first
    output = indexer.map_record(record)
  end
end

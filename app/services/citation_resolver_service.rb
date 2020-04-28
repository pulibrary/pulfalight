# frozen_string_literal: true

class CitationResolverService
  def self.config_path
    Rails.root.join("config", "citations.yml")
  end

  def self.citation_values
    config = File.read(config_path)
    document = YAML.parse(config)
    document.to_ruby
  end

  def self.resolve(repository_id:)
    return unless citation_values.key?(repository_id)

    citation_values[repository_id]
  end
end

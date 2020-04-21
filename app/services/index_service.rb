# frozen_string_literal: true

class IndexService
  def self.pulfa_root
    Rails.root.join("eads", "pulfa")
  end

  # Index an EAD-XML Document into Solr
  # @param [String] relative_path
  def index_document(relative_path:, root_path: nil)
    root_path ||= self.class.pulfa_root
    ead_file_path = File.join(root_path, relative_path)
    IndexJob.perform_later([ead_file_path])
  end
end

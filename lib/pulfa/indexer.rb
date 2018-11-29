module Pulfa
  class Indexer < Arclight::Indexer
    def normalize_title(data)

      Pulfa::CustomDocument::NormalizedTitle.new(
        data[:title],
        Arclight::NormalizedDate.new(
          data[:unitdate_inclusive],
          data[:unitdate_bulk],
          data[:unitdate_other]
        ).to_s
      ).to_s
    end
  end
end

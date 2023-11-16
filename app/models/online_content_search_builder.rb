# frozen_string_literal: true

class OnlineContentSearchBuilder < SearchBuilder
  self.default_processor_chain += [:switch_request_handler]

  def switch_request_handler(solr_parameters)
    solr_parameters[:qt] = "online-content"
  end
end

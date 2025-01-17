# frozen_string_literal: true
module Aspace
  class Client < ArchivesSpace::Client
    def self.config
      ArchivesSpace::Configuration.new(
        {
          base_uri: Pulfalight.config["archivespace_url"],
          username: Pulfalight.config["archivespace_user"],
          password: Pulfalight.config["archivespace_password"],
          page_size: 50,
          throttle: 0
        }
      )
    end

    def initialize
      super(self.class.config)
    end

    def login
      # Only login if there's no token.
      super unless @token
    end

    def ead_urls(modified_since: nil)
      login
      output = repositories.each_with_object({}) do |repository, acc|
        config.base_repo = repository["uri"][1..-1]
        query = { all_ids: true }
        query[:modified_since] = modified_since if modified_since
        resource_ids = get("resources", query: query).parsed
        urls = resource_ids.map do |resource_id|
          "#{config.base_repo}/resource_descriptions/#{resource_id}"
        end
        acc[repository["repo_code"]] = urls
      end
      config.base_repo = ""
      output
    end

    # returns nil if not found
    def ead_url_for_eadid(eadid:)
      login
      repositories.map do |repository|
        repository_uri = repository["uri"][1..-1]
        result = get("#{repository_uri}/search", query: { q: "identifier:#{eadid}", type: ["resource"], fields: ["uri", "identifier"], page: 1 }).parsed["results"][0]
        next if result.blank?
        code = repository["repo_code"].split("_").first.split("-").first
        code = "mss" if code == "Manuscripts"
        { result["uri"][1..-1].gsub("resources", "resource_descriptions") => code }
      end.to_a.compact.last
    end

    def get_xml(eadid:, cached: true)
      cache = XmlCache.where(ead_id: eadid).first
      return cache&.content if cache&.content&.present? && cached
      login
      url = ead_url_for_eadid(eadid: eadid).keys.first
      get_resource_description_xml(resource_descriptions_uri: url, cached: cached)
    end

    def get_resource_description_xml(resource_descriptions_uri:, cached: true)
      cache = XmlCache.find_or_initialize_by(resource_descriptions_uri: resource_descriptions_uri)
      return cache.content if cache.content.present? && cached
      login
      content = get("#{resource_descriptions_uri}.xml", query: { include_daos: true, include_unpublished: false }, timeout: 1200).body.force_encoding("UTF-8")
      # Strip prefix from EAD.
      content = content.gsub("id=\"aspace_", "id=\"")
      cache.content = content
      cache.ead_id = Nokogiri::XML.parse(content).remove_namespaces!.xpath("//eadid")[0].text
      cache.save!
      content
    end

    # This is quicker than doing a bunch of different kinds of calls,
    # and will get the object whether it's a collection (resource)
    #   (id will be in `identifier`)
    # or an archival_object (series, file, item)
    #   (id will be in `ref_id`)
    # note this will get the object whether it's published or not
    # returns nil if nothing found
    def get_basic_info(id:)
      login
      content = get(
        "/search",
        query: {
          q: id,
          page: 1,
          fields: ["ref_id", "identifier", "uri", "title"]
        }
      )
      parsed = content.parsed
      return unless parsed["total_hits"].positive?
      parsed["results"].find do |r|
        r["ref_id"]&.tr(".", "-") == id || r["identifier"]&.tr(".", "-") == id
      end
    end
  end
end

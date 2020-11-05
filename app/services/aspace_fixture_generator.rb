# frozen_string_literal: true
class AspaceFixtureGenerator
  def self.regenerate!
    new(client: Aspace::Client.new).regenerate!
  end

  attr_reader :client
  def initialize(client:)
    @client = client
  end

  def regenerate!
    FileUtils.mkdir_p(fixture_dir)
    fixture_files.each do |fixture_file|
      File.open(fixture_dir.join("#{fixture_file.eadid}.EAD.xml"), "w") do |f|
        f.puts(fixture_file.content)
      end
      process(fixture_file)
      Rails.logger.info "Regenerated #{fixture_file.eadid}"
    end
  end

  def fixture_dir
    Rails.root.join("spec", "fixtures", "aspace", "generated")
  end

  private

  def or_query
    fixtures.join(" OR ")
  end

  def process(fixture_file)
    return unless component_filter.key?(fixture_file.eadid)
    output = select_components(
      fixture_file,
      component_filter[fixture_file.eadid]
    )
    File.open(fixture_dir.join("#{fixture_file.eadid}.processed.EAD.xml"), "w") do |f|
      f.puts(output)
    end
  end

  def component_filter
    {
      "C0776" => [
        "aspace_C0776_c00071"
      ],
      "MC085" => [
        "aspace_MC085_c01078"
      ],
      "MC152" => [
        "aspace_MC152_c001",
        "aspace_MC152_c009",
        "aspace_MC152_c010"
      ],
      "MC221" => [
        "aspace_MC221_c0001",
        "aspace_MC221_c0002"
      ],
      "C0251" => [
        "aspace_C0251_c0001",
        "aspace_C0251_c0002",
        "aspace_C0251_c0007",
        "aspace_C0251_c0089",
        "aspace_C0251_c0091",
        "aspace_C0251_c0097",
        "aspace_C0251_c0101"
      ],
      "WC064" => ["aspace_WC064_c1"],
      "MC148" => [
        "aspace_MC148_c00002",
        "aspace_MC148_c00018"
      ]
    }
  end

  def select_components(fixture_file, components)
    doc = Nokogiri::XML(fixture_file.content)
    doc.remove_namespaces!
    doc.search("//c").each do |container|
      all_ids = container.search(".//c").map { |x| x["id"] }
      container.remove if !components.include?(container["id"]) && (all_ids & components).blank?
    end
    doc.to_xml
  end

  def eadids
    [
      "C0251",
      "C0776",
      "MC085",
      "MC152",
      "C1588",
      "MC221",
      "WC064",
      "MC148",
      "WC127"
    ]
  end

  def fixture_files
    @fixture_files ||=
      begin
        eadids.lazy.map do |eadid|
          uri = find_eadid_uri(eadid: eadid)
          ead_content = get_content(uri, eadid)
          EADContainer.new(eadid: eadid, content: ead_content)
        end
      end
  end

  def get_content(uri, eadid)
    file = fixture_dir.join("#{eadid}.EAD.xml")
    return File.read(file) if File.exist?(file)
    client.get("#{uri}.xml", query: { include_daos: true, include_unpublished: false }, timeout: 1200).body.force_encoding("UTF-8")
  end

  def find_eadid_uri(eadid:)
    client.recent_repositories.each do |repository|
      repository_uri = repository["uri"][1..-1]
      result = client.get("#{repository_uri}/search", query: { q: "identifier:#{eadid}", type: ["resource"], fields: ["uri", "identifier"], page: 1 }).parsed["results"][0]
      next if result.blank?
      return result["uri"][1..-1].gsub("resources", "resource_descriptions")
    end
  end

  class EADContainer
    attr_reader :eadid, :content
    def initialize(eadid:, content:)
      @eadid = eadid
      @content = content
    end
  end
end

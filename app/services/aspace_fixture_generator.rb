# frozen_string_literal: true
class AspaceFixtureGenerator
  def self.regenerate!
    new(client: Aspace::Client.new).regenerate!
  end

  # EAD IDs to pull down from ArchivesSpace.
  EAD_IDS = [
    "C0251",
    "C0776",
    "MC085",
    "MC152",
    "C1588",
    "MC221",
    "WC064",
    "MC148",
    "WC127",
    "C1408"
  ].freeze

  # List components per EAD which are used in tests to make processing those
  # EADs in the test suite faster.
  COMPONENT_MAP = {
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
      "aspace_MC148_c00018",
      "aspace_MC148_c07608"
    ],
    "C1408" => []
  }.freeze

  attr_reader :client
  def initialize(client:)
    @client = client
  end

  def regenerate!
    fixture_files.each do |fixture_file|
      FileUtils.mkdir_p(fixture_dir.join(fixture_file.repository))
      File.open(fixture_dir.join(fixture_file.repository, "#{fixture_file.eadid}.EAD.xml"), "w") do |f|
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

  # Filter an EAD to just the components in the component map and write it to a
  # separate file.
  def process(fixture_file)
    return unless COMPONENT_MAP.key?(fixture_file.eadid)
    output = select_components(
      fixture_file,
      COMPONENT_MAP[fixture_file.eadid]
    )
    File.open(fixture_dir.join(fixture_file.repository, "#{fixture_file.eadid}.processed.EAD.xml"), "w") do |f|
      f.puts(output)
    end
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

  def fixture_files
    @fixture_files ||=
      begin
        EAD_IDS.lazy.map do |eadid|
          uri, repo_code = client.ead_url_for_eadid(eadid: eadid)&.first
          ead_content = get_content(uri, eadid)
          EADContainer.new(eadid: eadid, content: ead_content, repository: repo_code)
        end
      end
  end

  def get_content(uri, eadid)
    file = fixture_dir.glob("**/*.EAD.xml").find { |x| x.to_s.ends_with?("#{eadid}.EAD.xml") }
    return File.read(file) if File.exist?(file)
    client.get("#{uri}.xml", query: { include_daos: true, include_unpublished: false }, timeout: 1200).body.force_encoding("UTF-8")
  end

  class EADContainer
    attr_reader :eadid, :content, :repository
    def initialize(eadid:, content:, repository:)
      @eadid = eadid
      @content = content
      @repository = repository.downcase
    end
  end
end

# frozen_string_literal: true
class AspaceFixtureGenerator
  # EAD IDs to pull down from ArchivesSpace.
  EAD_IDS = [
    "MC147",
    "C0662",
    "C0062",
    "C0251",
    "C0776",
    "MC085",
    "MC152",
    "C1588",
    "MC221",
    "WC064",
    "MC148",
    "WC127",
    "C1408",
    "MC001.02.06",
    "C1491",
    "C0274",
    "C0257",
    "C1513",
    "C1210",
    "C0841",
    "C1619",
    "C0033",
    "C0744.04",
    "C0744.03",
    "C1387",
    "C0140",
    "C0187",
    "C0269",
    "AC053",
    "AC154",
    "MC168",
    "C1165",
    "AC187",
    "AC259",
    "MC016",
    "AC198",
    "C1629",
    "AC136",
    "AC362",  # has james baker components
    "MC197",  # collection is called james baker
    "AC317",
    "MC014",
    "COTSEN4",
    "MC302",
    "C0292",
    "C0845",
    "C1436",
    "MC203",
    "AC130",
    "C1664",
    "C1539",
    "C0171",
    "C1372",
    "MC066",
    "C0958"
  ].freeze

  # List components per EAD which are used in tests to make processing those
  # EADs in the test suite faster.
  COMPONENT_MAP = {
    "C0062" => [],
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
      "aspace_C0251_c0101",
      "aspace_C0251_c0103"
    ],
    "WC064" => ["aspace_WC064_c1", "aspace_WC064_c2698"],
    "MC148" => [
      "aspace_MC148_c00002",
      "aspace_MC148_c00018",
      "aspace_MC148_c07608"
    ],
    "C1408" => ["aspace_C1408_c3"],
    "MC001.02.06" => [],
    "C1491" => [
      "aspace_C1491_c5621",
      "aspace_C1491_c5239",
      "aspace_C1491_c363",
      "aspace_C1491_c4",
      "aspace_C1491_c68"
    ],
    "C0274" => [],
    "C0257" => [],
    "C1513" => [],
    "C1210" => [],
    "C0841" => [],
    "C1619" => ["aspace_C1619_c24"],
    "C0033" => ["aspace_C0033_c001"],
    "C0744.04" => ["aspace_C0744.04_c0120"],
    "C0744.03" => ["aspace_C0744.03_c0516", "aspace_C0744.03_c0512"],
    "C1387" => ["aspace_C1387_c1"],
    "C0140" => ["aspace_C0140_c03411", "aspace_C0140_c29843-01832", "aspace_C0140_c83445-31032", "aspace_C0140_c80184-00264", "aspace_C0140_c89292-98183"],
    "C0187" => ["aspace_C0187_c00003"],
    "C0269" => ["aspace_C0269_c00693"],
    "AC053" => ["aspace_AC053_c4917"],
    "AC154" => ["aspace_AC154_c03425"],
    "MC168" => ["aspace_MC168_c02041"],
    "C1165" => [],
    "AC187" => ["aspace_AC187_c00654"],
    "AC259" => ["aspace_AC259_c005"],
    "MC016" => ["aspace_MC016_c1866"],
    "AC198" => [],
    "AC136" => ["aspace_AC136_c2889"],
    "AC362" => ["aspace_AC362_c01738", "aspace_AC362_c00815"],
    "MC197" => ["aspace_MC197_c04517"],
    "AC317" => ["aspace_AC317_c36874-31598"],
    "MC014" => ["aspace_MC014_c03682"],
    "MC147" => ["aspace_MC147_c07283-24964"],
    "MC302" => ["aspace_MC302_c21357-52777"],
    "C0292" => [],
    "C0845" => ["aspace_C0845_c0023"], # Used to test private Figgy material
    "C1436" => ["aspace_C1436_c547"], # Reading Room link resource
    "MC203" => ["aspace_MC203_c0238"], # Public link resource,
    "AC130" => ["aspace_AC130_c8346"],
    "C1664" => [],
    "C1539" => [],
    "C1372" => ["aspace_C1372_c47202-68234"],
    "C0171" => [],
    "C0958" => ["aspace_C0958_c06413-76702"]
  }.freeze

  attr_reader :client, :ead_ids, :component_map, :fixture_dir
  def initialize(client: Aspace::Client.new, ead_ids: EAD_IDS, component_map: COMPONENT_MAP, fixture_dir: Rails.root.join("spec", "fixtures", "aspace", "generated"))
    @client = client
    @ead_ids = ead_ids
    @component_map = component_map
    @fixture_dir = fixture_dir
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

  private

  # Filter an EAD to just the components in the component map and write it to a
  # separate file.
  def process(fixture_file)
    return unless component_map.key?(fixture_file.eadid)
    output = select_components(
      fixture_file,
      component_map[fixture_file.eadid]
    )
    File.open(fixture_dir.join(fixture_file.repository, "#{fixture_file.eadid}.processed.EAD.xml"), "w") do |f|
      f.puts(output)
    end
  end

  def select_components(fixture_file, components)
    doc = Nokogiri::XML(fixture_file.content)
    doc.search("//xmlns:c").each do |container|
      child_ids = container.search(".//xmlns:c").map { |x| x["id"] }
      next if components.include?(container["id"])
      # Don't remove the container if it contains a child which we want to save.
      next if (child_ids & components).present?
      container.remove
    end
    doc.to_xml
  end

  def fixture_files
    @fixture_files ||=
      ead_ids.lazy.map do |eadid|
        uri, repo_code = client.ead_url_for_eadid(eadid: eadid)&.first
        EADContainer.new(eadid: eadid, content: get_content(uri, eadid), repository: repo_code)
      end
  end

  # Only fetch content from ASpace if the file doesn't already exist.
  # @note This was added because sometimes these take a long time to fetch, and
  #   all we want to do is process the original to have more or less components
  #   for the test suite.
  def get_content(uri, eadid)
    file = fixture_dir.glob("**/*.EAD.xml").find { |x| x.to_s.ends_with?("#{eadid}.EAD.xml") }
    return File.read(file) if file.present?
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

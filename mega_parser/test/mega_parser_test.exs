defmodule MegaParserTest do
  use ExUnit.Case
  doctest MegaParser

  test "parse a0011" do
    file = File.read!("test/fixtures/a0011.xml")
    output = MegaParser.parse(file)
    assert output.id == "a0011-xml"
    assert output.ead_ssi == "a0011.xml"
    assert output.title_ssm == ["Stanford University student life photograph album"]
    %{components: components} = output
    first_component = hd(components)
    assert first_component.ref_ssi == "aspace_ref6_lx4"
    assert first_component.id == "a0011-xmlaspace_ref6_lx4"
    assert first_component.ead_ssi == output.ead_ssi
    assert first_component.has_online_content_ssim == [true]
    assert first_component.geogname_sim == []
    assert first_component.geogname_ssm == []
    assert first_component.collection_unitid_ssm == ["A0011"]

    container_component = Enum.find(components, fn(x) -> x.ref_ssi == "aspace_ref6_lx4" end)
    assert container_component.containers_ssim == ["box 1"]
  end


  test "parse alphaomegaalpha.xml" do
    file = File.read!("test/fixtures/alphaomegaalpha.xml")
    output = MegaParser.parse(file)
    %{components: components} = output

    level_component = Enum.find(components, fn(x) -> x.ref_ssi == "aspace_a951375d104030369a993ff943f61a77" end)
    assert level_component != nil
    assert level_component.level_ssm == "Series"
    assert level_component.level_sim == "Series"
    assert level_component.sort_ii == 32


    other_level_component = Enum.find(components, fn(x) -> x.ref_ssi == "aspace_e6db65d47e891d61d69c2798c68a8f02" end)
    assert other_level_component.level_ssm == "Binder"
    assert other_level_component.sort_ii == 1
  end

  require IEx
  test "large component list" do
    file = File.read!("test/fixtures/large-components-list.xml")
    output = MegaParser.parse(file)
    %{components: components} = output

    assert length(components) == 404

    nested_component = Enum.find(components, fn(x) -> x.ref_ssi == "aspace_32ad9025a3a286358baeae91b5d7696e" end)
    assert nested_component != nil
  end

  # describe 'large component list' do
  #   let(:fixture_path) do
  #     Arclight::Engine.root.join('spec', 'fixtures', 'ead', 'sample', 'large-components-list.xml')
  #   end
  #
  #   it 'selects the components' do
  #     expect(result['components'].length).to eq 404
  #   end
  #
  #   it 'indexes top-level daos' do
  #     expect(result['digital_objects_ssm']).to eq(
  #       [
  #         JSON.generate(
  #           label: '1st Street Arcade San Francisco',
  #           href: 'https://purl.stanford.edu/yy901zw2656'
  #         )
  #       ]
  #     )
  #   end
  #
  #   context 'when nested component' do
  #     let(:nested_component) { result['components'].find { |c| c['id'] == ['lc0100aspace_32ad9025a3a286358baeae91b5d7696e'] } }
  #
  #     it 'correctly determines component level' do
  #       expect(nested_component['component_level_isim']).to eq [2]
  #     end
  #
  #     it 'parent' do
  #       expect(nested_component['parent_ssim']).to eq %w[lc0100 aspace_327a75c226d44aa1a769edb4d2f13c6e]
  #       expect(nested_component['parent_ssi']).to eq ['aspace_327a75c226d44aa1a769edb4d2f13c6e']
  #     end
  #
  #     it 'parent_unittitles' do
  #       expect(nested_component['parent_unittitles_ssm']).to eq ['Large collection sample, 1843-1872', 'File 1']
  #     end
  #   end
  # end
end

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
    assert other_level_component.sort_ii == 2
  end


    #   describe 'levels' do
    #     let(:fixture_path) do
    #       Arclight::Engine.root.join('spec', 'fixtures', 'ead', 'nlm', 'alphaomegaalpha.xml')
    #     end
    #     let(:level_component) { result['components'].find { |c| c['ref_ssi'] == ['aspace_a951375d104030369a993ff943f61a77'] } }
    #     let(:other_level_component) { result['components'].find { |c| c['ref_ssi'] == ['aspace_e6db65d47e891d61d69c2798c68a8f02'] } }
    #
    #     it 'is the level Capitalized' do
    #       expect(level_component['level_ssm']).to eq(['Series'])
    #       expect(level_component['level_sim']).to eq(['Series'])
    #     end
    #
    #     it 'is the otherlevel attribute when the level attribute is "otherlevel"' do
    #       expect(other_level_component['level_ssm']).to eq(['Binder'])
    #       expect(other_level_component['level_sim']).to eq(['Binder'])
    #     end
    #
    #     it 'sort' do
    #       expect(other_level_component['sort_ii']).to eq([2])
    #       expect(level_component['sort_ii']).to eq([32])
    #     end
    #   end
    # end
end

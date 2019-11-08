defmodule MegaParser.SaxParserTest do
  use ExUnit.Case
  doctest MegaParser.SaxParser

  test "parse a0011" do
    output = MegaParser.parse("test/fixtures/a0011.xml", :sax)
    assert output.id == "a0011-xml"
    assert output.ead_ssi == "a0011.xml"
    assert output.title_ssm == ["Stanford University student life photograph album"]
    assert output.title_teim == output.title_ssm
    assert output.level_sim == ["Collection"]
    assert output.level_ssm == ["collection"]
    assert output.normalized_title_ssm == ["Stanford University student life photograph album, circa 1900-1906"]
    assert output.collection_ssm == output.normalized_title_ssm
    assert output.collection_sim == output.normalized_title_ssm
    assert output.collection_ssi == output.normalized_title_ssm
    assert output.collection_title_tesim == output.normalized_title_ssm
    # Do something about repository
    assert output.normalized_date_ssm == ["circa 1900-1906"]
    assert output.unitdate_ssm == ["circa 1900-1906"]
    assert output.unitdate_bulk_ssim == []
    assert output.unitdate_inclusive_ssm == ["circa 1900-1906"]
    assert output.unitdate_other_ssim == []
    assert output.date_range_sim == [1900, 1901, 1902, 1903, 1904, 1905, 1906]
    assert output.unitid_ssm == ["A0011"]
    assert output.unitid_teim == ["A0011"]
    assert output.collection_unitid_ssm == ["A0011"]
    assert output.geogname_ssm == ["Yosemite National Park (Calif.)"]
    assert output.geogname_sim == ["Yosemite National Park (Calif.)"]
    assert output.places_sim == output.geogname_ssm
    assert output.places_ssim == output.geogname_ssm
    assert output.places_ssm == output.geogname_ssm
    assert output.creator_ssm == ["Stanford University"]
    assert output.creator_sim == output.creator_ssm
    assert output.creator_ssim == output.creator_ssm
    assert output.creator_sort == "Stanford University"
    assert output.creator_corpname_ssm == ["Stanford University"]
    assert output.creator_corpname_sim == output.creator_corpname_ssm
    assert output.creator_corpname_ssim == output.creator_corpname_ssm
    assert output.creator_persname_ssm == []
    assert output.creator_persname_sim == output.creator_persname_ssm
    assert output.creator_persname_ssim == output.creator_persname_ssm
    assert output.creator_famname_ssm == []
    assert output.creator_famname_sim == output.creator_famname_ssm
    assert output.creator_famname_ssim == output.creator_famname_ssm
    assert output.creators_ssim == ["Stanford University"]

    assert output.persname_sim == ["Stanford, Leland"]

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
    output = MegaParser.parse("test/fixtures/alphaomegaalpha.xml", :sax)
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

  test "large component list" do
    output = MegaParser.parse("test/fixtures/large-components-list.xml", :sax)
    %{components: components} = output

    assert length(components) == 404

    nested_component = Enum.find(components, fn(x) -> x.ref_ssi == "aspace_32ad9025a3a286358baeae91b5d7696e" end)
    assert nested_component != nil
    assert nested_component.normalized_title_ssm == ["Item AA191"]
    assert nested_component.component_level_isim == [2]
    assert nested_component.parent_ssim == ["lc0100", "aspace_327a75c226d44aa1a769edb4d2f13c6e"]
    assert nested_component.parent_ssi == ["aspace_327a75c226d44aa1a769edb4d2f13c6e"]
    assert nested_component.parent_unittitles_ssm == ["Large collection sample, 1843-1872", "File 1"]
  end
end

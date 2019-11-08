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

    assert output.access_terms_ssm == [
      "All requests to reproduce, publish, quote from, or otherwise use collection materials must be submitted in writing to the Head of Special Collections and University Archives, Stanford University Libraries, Stanford, California 94304-6064. Consent is given on behalf of Special Collections as the owner of the physical items and is not intended to include or imply permission from the copyright owner. Such permission must be obtained from the copyright owner, heir(s) or assigns. See: http://library.stanford.edu/depts/spc/pubserv/permissions.html.",
      "Restrictions also apply to digital representations of the original materials. Use of digital files is restricted to research and educational purposes."
    ]
    assert output.acqinfo_ssim == []
    assert output.access_subjects_ssim == ["Photoprints.", "Cyanotypes."]
    assert output.access_subjects_ssm == output.access_subjects_ssim
    assert output.has_online_content_ssim == [true]
    # TODO: Make this do something.
    assert output.digital_objects_ssm == []

    assert output.extent_ssm == ["1.25 Linear Feet", "(1 volume)"]
    assert output.extent_teim == output.extent_ssm
    assert output.genreform_ssm == ["Photoprints.", "Cyanotypes."]
    assert output.genreform_sim == output.genreform_ssm
    assert output.date_range_sim == [1900, 1901, 1902, 1903, 1904, 1905, 1906]
    assert output.altformavail_teim == [
      "The entire album has been digitized and is available online here: http://purl.stanford.edu/kc844kt2526"
    ]
    assert output.altformavail_heading_ssm == [
      "Existence and Location of Copies"
    ]

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
    assert output.acqinfo_ssim == ["Donated by Alpha Omega Alpha."]
    assert output.acqinfo_ssm == output.acqinfo_ssim
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

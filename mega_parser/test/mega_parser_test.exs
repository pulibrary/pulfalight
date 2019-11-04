defmodule MegaParserTest do
  use ExUnit.Case
  doctest MegaParser

  test "parse" do
    file = File.read!("test/fixtures/MC057.xml")
    output = MegaParser.parse(file)
    assert output.id == "MC057"
    assert output.title_ssm == ["Franklin Book Programs Records"]
  end
end

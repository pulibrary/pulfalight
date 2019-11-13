file = File.read!("test/fixtures/MC057.xml")
Benchee.run(%{
  # "Meeseeks"    => fn -> 
  #   MegaParser.parse(file)
  # end,
  "Sax"        => fn ->
    MegaParser.parse("test/fixtures/MC057.xml", :sax)
  end
})

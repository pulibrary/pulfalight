file = File.read!("test/fixtures/MC057.xml")
Benchee.run(%{
  "pleasenobreak"    => fn -> 
    MegaParser.parse(file)
  end,
})

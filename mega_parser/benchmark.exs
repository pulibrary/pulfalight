file = File.read!("megamc.ead.xml")
Benchee.run(%{
  "pleasenobreak"    => fn -> 
    MegaParser.parse(file)
  end,
})

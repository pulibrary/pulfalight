# frozen_string_literal: true

module Pulfalight
  class CodeResolver
    def self.codes
      {}
    end

    def self.translate_code(code)
      codes[code]
    end

    def self.resolve(code)
      translate(code)
    end
  end

  class LocationResolver < CodeResolver
    def self.codes
      {
        "cotsen" => "Firestone Library",
        "ex" => "Firestone Library",
        "gax" => "Firestone Library",
        "ga" => "Firestone Library",
        "mss" => "Firestone Library",
        "njpg" => "Firestone Library",
        "thx" => "Firestone Library",
        "wa" => "Firestone Library",
        "hsvc" => "Firestone Library",
        "hsvg" => "Firestone Library",
        "hsvm" => "Firestone Library",
        "hsvr" => "Firestone Library",
        "mudd" => "Mudd Manuscript Library",
        "rcppa" => "ReCAP",
        "rcppf" => "ReCAP",
        "rcpph" => "ReCAP",
        "rcpxc" => "ReCAP",
        "rcpxg" => "ReCAP",
        "rcpxm" => "ReCAP",
        "rcpxr" => "ReCAP",
        "selectors" => "ReCAP",
        "flm" => "Firestone Library",
        "st" => "Engineering Library",
        "anxb" => "Annex B",
        "ppl" => "Plasma Physics Library"
      }
    end
  end

  class PhysicalLocationResolver < CodeResolver
    def self.codes
      {
        "eng" => "Engineering Library",
        "lae" => "RBSC",
        "selectors" => "RBSC",
        "mss" => "RBSC",
        "rarebooks" => "RBSC",
        "cotsen" => "RBSC",
        "ga" => "RBSC",
        "publicpolicy" => "MUDD",
        "univarchives" => "MUDD"
      }
    end
  end
end

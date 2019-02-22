# frozen_string_literal: true
module Pulfa
  class CustomComponent < Arclight::CustomComponent
    include IndexingBehavior
  end
end

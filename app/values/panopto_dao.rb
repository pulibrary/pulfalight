# frozen_string_literal: true
class PanoptoDao < SimpleDelegator
  def id
    __getobj__.href.split("?").last.gsub("id=", "")
  end
end

# frozen_string_literal: true
module ApplicationHelper
  def on_home_page?
    controller_name == "catalog" && params[:action] == "index" && !has_search_parameters?
  end
end

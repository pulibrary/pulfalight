# frozen_string_literal: true
class AddEadIdToXmlCache < ActiveRecord::Migration[5.2]
  def change
    add_column :xml_caches, :ead_id, :string
  end
end

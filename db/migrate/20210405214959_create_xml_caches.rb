# frozen_string_literal: true
class CreateXmlCaches < ActiveRecord::Migration[5.2]
  def change
    create_table :xml_caches do |t|
      t.string :resource_descriptions_uri
      t.text :content

      t.timestamps
    end
  end
end

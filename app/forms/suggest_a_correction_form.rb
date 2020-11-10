# frozen_string_literal: true
class SuggestACorrectionForm
  include ActiveModel::Model
  attr_accessor :name, :email, :box_number, :message, :location_code

  validates :name, :email, :message, presence: true
end

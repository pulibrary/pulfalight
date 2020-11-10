# frozen_string_literal: true
class ContactController < ApplicationController
  def suggest
    @form = SuggestACorrectionForm.new(suggest_params)
    if !@form.valid?
      render partial: "catalog/correction_form", locals: { form: @form }, status: :unprocessable_entity
    end
  end

  def suggest_params
    params[:suggest_a_correction_form].permit!
  end
end

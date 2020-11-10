# frozen_string_literal: true
class ContactController < ApplicationController
  def suggest
    @form = SuggestACorrectionForm.new(suggest_params)
    if @form.valid? && @form.submit
      ContactMailer.with(form: @form).suggest.deliver
      render status: :ok, body: nil
    else
      render partial: "catalog/correction_form", locals: { form: @form }, status: :unprocessable_entity
    end
  end

  def suggest_params
    params[:suggest_a_correction_form].permit!
  end
end

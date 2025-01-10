# frozen_string_literal: true
class ContactController < ApplicationController
  def suggest
    @form = SuggestACorrectionForm.new(suggest_params)
    if @form.valid? && @form.submit
      render partial: "catalog/correction_form", locals: { form: @form }
    else
      render partial: "catalog/correction_form", locals: { form: @form }, status: :unprocessable_entity
    end
  end

  def question
    @form = AskAQuestionForm.new(question_params)
    if @form.valid? && @form.submit
      render partial: "catalog/ask_a_question_form", locals: { form: @form }
    else
      render partial: "catalog/ask_a_question_form", locals: { form: @form }, status: :unprocessable_entity
    end
  end

  def suggest_params
    params[:suggest_a_correction_form].permit!
  end

  def question_params
    params[:ask_a_question_form].permit!
  end
end

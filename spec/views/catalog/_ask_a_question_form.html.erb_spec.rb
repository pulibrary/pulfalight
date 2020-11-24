# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_ask_a_question_form.html.erb" do
  it "renders a form" do
    form = AskAQuestionForm.new(location_code: "mss", context: "http://test.com/catalog/1", title: "Bananas")

    render partial: "catalog/ask_a_question_form", locals: { form: form }

    expect(rendered).to have_field "Name"
    expect(rendered).to have_field "Email"
    expect(rendered).to have_field "Message"
    expect(rendered).to have_field "ask_a_question_form_location_code", type: :hidden, with: "mss"
    expect(rendered).to have_field "ask_a_question_form_title", type: :hidden, with: "Bananas"
    expect(rendered).to have_field "ask_a_question_form_context", type: :hidden, with: "http://test.com/catalog/1"
    expect(rendered).to have_select "Subject", options: [
      "This Collection",
      "Reproductions & Photocopies",
      "Rights & Permissions",
      "Access",
      "Other"
    ]
    expect(rendered).to have_button "Send"
    expect(rendered).to have_css("form[data-remote=true][action='/contact/question']")
  end
end

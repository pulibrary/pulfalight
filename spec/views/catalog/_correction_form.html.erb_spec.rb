# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_correction_form.html.erb" do
  it "renders a form" do
    form = SuggestACorrectionForm.new(location_code: "mss", context: "http://test.com/catalog/1")

    render partial: "catalog/correction_form", locals: { form: form }

    expect(rendered).to have_field "Name"
    expect(rendered).to have_field "Email"
    expect(rendered).to have_field "Box/Container Number (optional)"
    expect(rendered).to have_field "Message"
    expect(rendered).to have_field "suggest_a_correction_form_location_code", type: :hidden, with: "mss"
    expect(rendered).to have_field "suggest_a_correction_form_context", type: :hidden, with: "http://test.com/catalog/1"
    expect(rendered).to have_button "Send"
    expect(rendered).to have_css("form[data-remote=true][action='/contact/suggest']")
  end
end

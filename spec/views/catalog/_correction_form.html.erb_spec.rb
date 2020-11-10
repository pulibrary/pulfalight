# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_correction_form.html.erb" do
  it "renders a form" do
    form = SuggestACorrectionForm.new

    render partial: "catalog/correction_form", locals: { form: form }

    expect(rendered).to have_field "Name"
    expect(rendered).to have_field "Email"
    expect(rendered).to have_field "Box/Container Number (optional)"
    expect(rendered).to have_field "Message"
    expect(rendered).to have_button "Send"
    expect(rendered).to have_css("form[data-remote=true]")
  end
end

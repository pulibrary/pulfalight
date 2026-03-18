# frozen_string_literal: true
# This module identifies spam bots based on them
# filling out a "honeypot" field.
module Honeypot
  attr_accessor :feedback

    private

  def spam?
    # feedback is a hidden field that is not presented
    # to human users.  If `feedback` is present, it was almost
    # certainly filled in by a spam robot.
    feedback.present?
  end
end

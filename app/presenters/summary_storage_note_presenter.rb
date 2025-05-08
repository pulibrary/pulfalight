# frozen_string_literal: true

class SummaryStorageNotePresenter
  include ActionView::Context
  include ActionView::Helpers::TextHelper

  attr_reader :document
  def initialize(document)
    @document = document
  end

  def render
    notes = document.fetch(:summary_storage_note_ssm, [])
    return if notes.blank?
    notes_hash = JSON.parse(notes.first)
    list = 
      content_tag(:ul) do
        notes_hash.each do |list_item, nested_items|
          concat(content_tag(:li, list_item))
          if nested_items.present?
            concat(content_tag(:ul) do
              nested_items.each do |item|
                concat(content_tag(:li, item))
              end
            end)
          end
        end
      end
    return list if notes_hash.keys.size == 1
    tag.span("This is stored in multiple locations.").concat(list)
  rescue JSON::ParserError
    processed_notes = process_summary_notes(notes)
    content_tag(:ul) do
      processed_notes.map do |note|
        concat(content_tag(:li, note))
      end
    end
  end

  # ["<ul>",
  #         "<li>This is stored in multiple locations.</li>",
  #         "<li>Firestone Library (scahsvm):</li>",
  #         "<ul><li>Boxes 1-11; 13-19</li></ul>",
  #         "<li>Firestone Library (scamss):</li>",
  #         "<ul><li>Boxes 12, 20 to 21</li></ul>",
  #         "</ul>"].join

  private

  # This method computes ranges for abid'd boxes, e.g. "P-042356 to P-042359"
  # Ranges for fully numerical containers are computed at indexing time in normalized_box_locations.rb
  def process_summary_notes(notes)
    notes.map do |note|
      abid_matcher = note.match(/^(?<location>.*: Boxes )(?:(?:[A-Z]-)?\d{1,6}; )+/)
      if abid_matcher
        boxes = note.scan(/(?:[A-Z]-)?\d{1,6}/).sort
        note = "#{abid_matcher[:location]}#{boxes_to_range(boxes)}"
      end
      note
    end
  end

  def process_summary_notes_new(notes)
    notes.map do |note|
      abid_matcher = note.match(/^(?<location>.*: Boxes )(?:(?:[A-Z]-)?\d{1,6}; )+/)
      if abid_matcher
        boxes = note.scan(/(?:[A-Z]-)?\d{1,6}/).sort
        note = "#{abid_matcher[:location]}#{boxes_to_range(boxes)}"
      end
      note
    end
  end

  def consecutive?(box1, box2)
    same_prefix = box1.gsub(/\d/, "") == box2.gsub(/\d/, "")
    return false unless same_prefix
    box2.gsub(/\D/, "").to_i == box1.gsub(/\D/, "").to_i + 1 # compares integer portion of box number
  end

  def consecutive_chunk(output, boxes)
    first = boxes.first
    boxes.shift while boxes.length > 1 && consecutive?(boxes[0], boxes[1])
    return [output.push(boxes.shift), boxes] if first == boxes.first
    [output.push("#{first} to #{boxes.shift}"), boxes]
  end

  def boxes_to_range(boxes)
    output, boxes = consecutive_chunk(output ||= [], boxes) while boxes != []
    output.join(", ")
  end

  # Render an html <title> appropriate string for a set of search parameters
  # @param [ActionController::Parameters] params2
  # @return [String]
  def render_search_to_page_header(params)
    constraints = []
    constraints += params.dig("f", "collection_sim") || []
    constraints.join(" / ")
  end
end

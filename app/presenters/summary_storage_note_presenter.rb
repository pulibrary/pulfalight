# frozen_string_literal: true

class SummaryStorageNotePresenter
  include ActionView::Context
  include ActionView::Helpers::TextHelper

  attr_reader :document
  def initialize(document)
    @document = document
  end

  def get_notes(symbol)
    document.fetch(symbol, [])
  end

  def make_nested_locations_list(notes)
    return if notes.empty?
    hash = JSON.parse(notes.first)
    list = content_tag(:dl, class: "storage-notes") do
      hash.each do |list_item, nested_items|
        concat(content_tag(:dt, list_item))
        next if nested_items.blank?
        collapse_abid_ranges(nested_items).each do |item|
          concat(content_tag(:dd, item))
        end
      end
    end
    return list if hash.keys.size == 1
    # if there are multiple locations prepend a note
    tag.span("This is stored in multiple locations.").concat(list)
  end

  def build_notes_appendix(text_notes)
    return if text_notes.blank?
    appendices =
      text_notes.map do |note|
        tag.div(note)
      end
    appendices_header = content_tag(:div, "Note", class: "header")
    content_tag(:span, safe_join([appendices_header, appendices].compact.reject(&:empty?)), class: "storage-notes-appendix")
  end

  def append_to_list(list, text_notes)
    appendix = build_notes_appendix(text_notes)
    safe_join([list, appendix])
  end

  def render
    # storage notes with locations are key=>value pairs
    notes = get_notes(:summary_storage_note_ssm)
    # whereas text notes don't have a location key
    text_notes = get_notes(:location_note_ssm)
    list = make_nested_locations_list(notes)
    # add text notes to list of locations
    append_to_list(list, text_notes)
  end

  private

  # This method computes ranges for abid'd boxes, e.g. "P-042356 to P-042359"
  # Ranges for fully numerical containers are computed at indexing time in normalized_box_locations.rb
  def collapse_abid_ranges(notes)
    notes.map do |note|
      # multi-line syntax ignores literal spaces so use \s
      note_matcher = /
        ^(?<type>[\w]+?\s)                # types like boxes
        (?:(?:\d{1,3}-\d{1,3};\s)?|       # match when there is a numeric box range like 12-24
        (?:\d{1,3};\s)?)*                 # match when there is a non-range numeric box like 2
        (?:(?:(?:[A-Z]-?)\d{1,6};\s)|     # abid like P-042356 or M1
        (?:\w+\s\w+\s\d{1,4};\s))+        # abid like oversize folder 215
      /x
      abid_matcher = note.match(note_matcher)
      box_matcher = /
        (?:[A-Z]-?)\d{1,6}|                   # abid like P-042356 or M1
        [A-Za-z]+\s[A-Za-z]+\s\d{1,4}|        # abid like oversize folder 215
        [A-Za-z]+\s[A-Za-z]+(?:\s[A-Za-z]+)?  # catch phrases like Folder not located or Not located
      /x
      if abid_matcher
        boxes = note.scan(box_matcher).sort_by do |s|
          s.split(/(\d+)/).map do |chunk|
            chunk =~ /\d+/ ? chunk.to_i : chunk
          end
        end
        note = "#{abid_matcher[:type]}#{boxes_to_range(boxes)}"
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
end

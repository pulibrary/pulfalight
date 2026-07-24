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
    partition_notes(notes).map do |notes_field|
      type = notes_field.pop
      notes_field.map do |partition|
        next if partition.empty?

        boxes = sort_partition(partition)
        if partition[0].include?("oversize folder")
          boxes = boxes.map { |box| box.split(" ").last }
          note = "Oversize folder #{boxes_to_range(boxes)}"
        elsif partition.none? { |box| box.match?(/\d/) }
          note = partition.join("; ")
        else
          note = "#{type} #{boxes_to_range(boxes)}"
        end
        note
      end.compact
    end.flatten
  end

  def partition_notes(notes)
    collected_notes = []
    notes.map do |note|
      remaining = note.split(/; |;/)
      type, first_box = remaining[0].split(" ", 2)
      remaining[0] = first_box
      numeric, remaining = remaining.partition { |box| box.match?(/\A[\d-]+\z/) }
      alphanumeric, remaining = remaining.partition { |box| box.match?(/[A-Z]-?\d{1,6}/) }
      oversize, remaining = remaining.partition { |box| box.downcase.include?("oversize folder") }
      collected_notes.push([numeric, alphanumeric, oversize, remaining, type])
    end
    collected_notes
  end

  def sort_partition(partition)
    partition.sort_by do |s|
      s.split(/(\d+)/).map do |chunk|
        /\d+/.match?(chunk) ? chunk.to_i : chunk
      end
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
    output.join("; ")
  end
end

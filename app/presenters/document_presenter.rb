# frozen_string_literal: true

# This is intended to be used as an abstract base class
class DocumentPresenter
  def initialize(document)
    @document = document
  end

  def self.request_class
    Pulfalight::Requests::AeonExternalRequest
  end

  def request
    @request ||= self.class.request_class.new(@document, self) if requestable?
  end

  def request_form_params
    @request_form_params ||= build_request_form_params
  end

  # This seems to deprecate the AeonExternalRequest Class
  def request_attributes
    {
      callnumber: @document.parent_ids.first,
      referencenumber: @request.eadid,
      title: @document.title.first,
      containers: @request.containers, # add this,
      subcontainers: @request.subcontainers, # add this
      unitid: @request.unitid,
      physloc: "rcpxm",
      location: "mudd",
      subtitle: @document.subtitle.first,
      itemdate: @document.normalized_date.first,
      itemnumber: @request.id, # This should not be coupled here
      itemvolume: @document.volume.first,
      accessnote: @request.accessnote,
      extent: @request.extent,
      itemurl: @request.url
    }
  end

  def requestable?
    @document.repository_config.present?
  end

  private

  def form_mapping
    request.form_mapping
  end

  # Copied from blacklight 7.2.0
  def flatten_hash(hash, ancestor_names = [])
    flat_hash = {}
    hash.each do |k, v|
      names = Array.new(ancestor_names)
      names << k
      if v.is_a?(Hash)
        flat_hash.merge!(flatten_hash(v, names))
      else
        key = flat_hash_key(names)
        flat_hash[key] = v
      end
    end

    flat_hash
  end

  # Copied from blacklight 7.2.0
  def flat_hash_key(names)
    names = Array.new(names)
    name = names.shift.to_s.dup
    names.each do |n|
      name << "[#{n}]"
    end
    name
  end

  def build_request_form_params
    hidden_fields = []
    flatten_hash(form_mapping).each do |name, value|
      value = Array.wrap(value)
      value.each do |v|
        hidden_fields << { name: name, values: [ v.to_s ], id: nil }
      end
    end

    hidden_fields
  end
end

# frozen_string_literal: true

class HoursBuilder
  def self.build(id:)
    new(id: id).build
  end

  attr_reader :id
  def initialize(id:)
    @id = id.to_i
  end

  def build
    # Return if id parameter is not an integer
    return hours_hash(unvailable_message) if id.zero?
    response = query_lib_cal
    # Return if LibCal can't be reached
    return hours_hash(unvailable_message) unless response
    value = parse_response(response)
    # Return if LibCal response can't be parsed
    return hours_hash(unvailable_message) unless value
    hours_hash(value)
  end

  private

  def hours_hash(value)
    {
      hours: value
    }
  end

  def lib_cal_url
    "https://libcal.princeton.edu/api_hours_today.php?iid=771&lid=#{id}&format=json&systemTime=1"
  end

  def parse_response(response)
    json_response = JSON.parse(response.body)
    return if json_response.empty?
    locations = json_response["locations"].select { |loc| loc["lid"] == id }
    location = locations.try(:first)
    return unless location
    location["rendered"]
  end

  def query_lib_cal
    conn = Faraday.new(url: lib_cal_url)
    conn.get
  rescue Faraday::Error::ConnectionFailed
    Rails.logger.info("Unable to Connect to #{lib_cal_url}")
    false
  end

  def unvailable_message
    "Not available"
  end
end

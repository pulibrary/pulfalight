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
    { hours: value }
  end

  private

  def lib_cal_url
    "https://libcal.princeton.edu/api_hours_today.php?iid=771&lid=#{id}&format=json&systemTime=1"
  end

  def parsed_response
    @parsed_response ||= begin
                           json_response = JSON.parse(response.body)
                           return if json_response.empty?
                           locations = json_response["locations"].select { |loc| loc["lid"] == id }
                           location = locations.try(:first)
                           return unless location
                           location["rendered"]
                         end
  end

  def response
    @response ||= begin
                    conn = Faraday.new(url: lib_cal_url)
                    conn.get
                  rescue Faraday::ConnectionFailed
                    Rails.logger.info("Unable to Connect to #{lib_cal_url}")
                    false
                  end
  end

  def unavailable_message
    "Not available"
  end

  def value
    return unavailable_message if id.zero? # id is not an integer
    return unavailable_message unless response
    return unavailable_message unless parsed_response
    parsed_response
  end
end

# frozen_string_literal: false

class RobotsGeneratorService
  # Generate a robots.txt with the default values
  def self.default
    file_path = Rails.public_path.join("robots.txt")
    robots = RobotsGeneratorService.new(
      path: file_path,
      disallowed_paths: Rails.configuration.robots.disallowed_paths
    )
    robots.insert_group(user_agent: "*")
    robots.insert_crawl_delay(10)
    robots.insert_sitemap(Rails.configuration.robots.sitemap_url)
    robots.generate
    robots.write
  end

  def initialize(path:, disallowed_paths: [])
    @path = path
    @disallowed_paths = disallowed_paths

    @groups = [[]]
    @content = ""
  end

  def disallow(pattern)
    @groups.last << "Disallow: #{pattern}\n"
  end

  def generate
    generate_disallow_directives
    @groups.each do |rules|
      rules.each do |rule|
        @content << rule
      end
    end
  end

  def write
    File.open(@path, "w+b") do |f|
      f << @content
    end
  end

  def insert_group(user_agent:)
    @groups << []
    @content << "User-agent: #{user_agent}\n"
  end

  def insert_crawl_delay(delay)
    @content << "Crawl-delay: #{delay}\n"
  end

  def insert_sitemap(sitemap_url)
    @content << "Sitemap: #{sitemap_url}\n"
  end

  private

  def generate_disallow_directives
    @disallowed_paths.each do |path|
      disallow(path)
    end
  end
end

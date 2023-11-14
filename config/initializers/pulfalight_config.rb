# frozen_string_literal: true
module Pulfalight
  def config
    @config ||= config_yaml.with_indifferent_access
  end

  def multiple_algorithms_enabled?
    config[:multiple_algorithms] == true
  end

  private

  def config_yaml
    YAML.safe_load(yaml, aliases: true)[Rails.env]
  end

  def yaml
    ERB.new(File.read(Rails.root.join("config", "config.yml"))).result
  end

  module_function :config, :config_yaml, :yaml, :multiple_algorithms_enabled?
end

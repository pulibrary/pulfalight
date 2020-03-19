# frozen_string_literal: true
module Plantain
  def config
    @config ||= config_yaml.with_indifferent_access
  end

  private

    def config_yaml
      # This invocation will change in ruby 2.6 to
      # YAML.safe_load(yaml, aliases: true)[Rails.env]
      YAML.safe_load(yaml, [], [], true)[Rails.env]
    end

    def yaml
      ERB.new(File.read(Rails.root.join("config", "config.yml"))).result
    end

    module_function :config, :config_yaml, :yaml
end

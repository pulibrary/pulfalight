# frozen_string_literal: true
module MultipleAlgorithms
  class << self
    # When adding a new Ranking Algorithm the name will need to be added to this variable before it can be utilized.
    # For example if you added a cats ranking algorithm, with a CatsSearchBuilder you would set this variable
    # in the catalog controller and add "cats" to the list  `MultipleAlgorithms.allowed_search_algorithms = ["default", "cats"]`
    # This is to make sure the user can not just execute any SearchBuilder in the system.
    attr_accessor :allowed_search_algorithms
  end

  def search_service_context
    return {} unless Pulfalight.multiple_algorithms_enabled?
    return {} unless alternate_search_builder_class # use default if none specified
    { search_builder_class: alternate_search_builder_class }
  end

  def alternate_search_builder_class
    return unless search_algorithm_param && MultipleAlgorithms.allowed_search_algorithms.include?(search_algorithm_param)

    "#{search_algorithm_param}_search_builder".camelize.constantize
  end

  def search_algorithm_param
    params[:search_algorithm]
  end
end

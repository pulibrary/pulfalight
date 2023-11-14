# frozen_string_literal: true
module MultipleAlgorithms
  def search_service_context
    return {} unless multiple_algorithms_enabled?
    return {} unless alternate_search_builder_class # use default if none specified
    { search_builder_class: alternate_search_builder_class }
  end

  def alternate_search_builder_class
    return unless search_algorithm_param && allowed_search_algorithms.include?(search_algorithm_param)

    "#{search_algorithm_param}_search_builder".camelize.constantize
  end

  # When adding a new Ranking Algorithm the name will need to be added to this list before it can be utilized
  # For example if you added a cats ranking algorithm, with a CatsSearchBuilder you would add "cats" to this list ["engineering","cats"]
  # This is to make sure the user can not just execute any SearchBuilder in the system
  def allowed_search_algorithms
    ["online_content"]
  end

  def search_algorithm_param
    params[:search_algorithm]
  end

  def multiple_algorithms_enabled?
    true
  end
end

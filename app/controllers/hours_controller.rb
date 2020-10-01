# frozen_string_literal: true
class HoursController < ApplicationController
  def hours
    render json: HoursBuilder.build(id: params[:id])
  end
end

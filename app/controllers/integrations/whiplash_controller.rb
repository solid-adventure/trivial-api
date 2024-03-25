class Integrations::WhiplashController < ApplicationController

  def get_customers_by_id
      render json: whiplash.get_customers_by_id(action_params[:ids])
    rescue => e
      logger.error "Whiplash API call failed: #{e}"
      render json: {error: "Unable to get Whiplash customers by ID"}, status: 500
  end

  def get_customers_by_name
      render json: whiplash.get_customers_by_name(action_params[:name])
    rescue => e
      logger.error "Whiplash API call failed: #{e}"
      render json: {error: "Unable to get Whiplash customers by Name"}, status: 500
  end

  private

  def whiplash
    @whiplash ||= Integrations::Whiplash.new
  end

  def action_params
    params.permit(:ids, :name)
  end

end



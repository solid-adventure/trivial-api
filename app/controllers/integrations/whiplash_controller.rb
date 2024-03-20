class Integrations::WhiplashController < ApplicationController

  def get_customers_by_id
      whiplash = Integrations::Whiplash.new
      render json: whiplash.getCustomersById(action_params[:ids])
    rescue => e
      render json: {error: "Unable to get Whiplash customers by ID"}, status: 500
  end

  def get_customers_by_name
      whiplash = Integrations::Whiplash.new
      render json: whiplash.getCustomersByName(action_params[:name])
    rescue => e
      render json: {error: "Unable to get Whiplash customers by Name"}, status: 500
  end

  private

  def action_params
    params.permit(:ids, :name)
  end

end



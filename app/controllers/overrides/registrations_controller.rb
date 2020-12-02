# frozen_string_literal: true

module Overrides
  class RegistrationsController < DeviseTokenAuth::RegistrationsController
    skip_before_action :authenticate_user!, only: [:create]

    def create
      super

      return unless @resource.save && params[:team_name].present?

      team = Team.find_or_initialize_by(name: params[:team_name])

      if team.new_record?
        team.save
        @resource.role = 'team_manager'
        @resource.approval = 'approved'
      else
        @resource.role = 'member'
        @resource.approval = 'pending'
      end
      @resource.team = team

      @resource.save
    end

    def render_create_success
      render json: {
        status: 'success'
      }
    end
  end
end

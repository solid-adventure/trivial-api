class WebhooksController < ApplicationController
    MAX_RESULTS = 100

    skip_before_action :authenticate_user!, only: [:create, :update]

    def index
        render json: webhooks.map(&:legacy_attributes).to_json
    end

    def create
        @entry = ActivityEntry.new(activity_entry_params)
        @entry.activity_type = 'request'
        @entry.app = App.kept.find_by_name!(params[:app_id])
        @entry.user_id = @entry.app.user_id
        @entry.normalize_json
        @entry.save!
        @entry.publish_receipt!
        render status: :created, json: @entry.legacy_attributes
    end

    def show
        render json: webhook.legacy_attributes
    end

    def update
      updatable_webhook.update!(entry_update_params)
      render json: updatable_webhook.legacy_attributes
    end

    def send_new
      @app = current_user.apps.kept.find_by_name!(params[:id])
      res = ActivityEntry.send_new @app, params[:payload].to_json
      render json: {status: res.code.to_i, message: res.message}
    end

    def resend
        res = webhook.resend
        render json: {status: res.code.to_i, message: res.message}
    end

    private

    def webhook
        @webhook ||= current_user.activity_entries.requests.find(params[:id])
    end

    def updatable_webhook
      @updatable_webhook ||= ActivityEntry.updatable.find_by_update_id!(params[:id])
    end

    def webhooks
        @webhooks ||= current_user.apps.find_by_name!(params[:app_id]).activity_entries.requests.limit(limit).order(created_at: :desc)
    end

    def limit
      [[(params[:limit] || MAX_RESULTS).to_i, 1].max, MAX_RESULTS].min
    end

    def activity_entry_params
      @activity_params = {}.merge(params.permit(:source, :status))
      # :payload and :diagnostics may be a string or object
      @activity_params[:payload] = params[:payload]
      @activity_params[:diagnostics] = params[:diagnostics]
      @activity_params
    end

    def entry_update_params
      params.permit(:status, :duration_ms, diagnostics: {})
    end
end

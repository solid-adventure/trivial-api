class WebhooksController < ApplicationController
    MAX_RESULTS = 100

    skip_before_action :authenticate_user!, only: [:create, :update]
    before_action :authenticate_app_id!, only: [:stats]

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
      @app = App.kept.find_by_name!(params[:id])
      authorize! :read, @app
      @bodyPayload = JSON.parse(request.body.read)
      res = ActivityEntry.send_new @app, @bodyPayload["payload"].to_json
      render json: {status: res.code.to_i, message: res.message}
    end

    def resend
        res = webhook.resend
        render json: {status: res.code.to_i, message: res.message}
    end

    def subscribe
      render json: Webhook.wait_for_newer(current_user, params[:app_id], params[:last_seen]).to_json
    end

    private

    def webhook
        @webhook ||= ActivityEntry.accessible_by(Ability.new(current_user)).requests.find(params[:id])
    end

    def updatable_webhook
      @updatable_webhook ||= ActivityEntry.updatable.find_by_update_id!(params[:id])
    end

    def webhooks
      app = App.kept.find_by_name!(params[:app_id])
      authorize! :read, app
      @webhooks ||= app.activity_entries.requests.limit(limit).order(created_at: :desc)
    end

    def limit
      [[(params[:limit] || MAX_RESULTS).to_i, 1].max, MAX_RESULTS].min
    end

    def webhook_app_id
        @_webhook_app ||= Webhook.find_by(app_id: params[:app_id])
    end

    def webhook_params
        params.permit(:app_id, :payload, :source, :topic, :status, :diagnostics)
    end

    def authenticate_app_id!
      app = App.kept.find_by_name!(webhook_params[:app_id])
      authorize! :read, app
      return app
    end

    def activity_entry_params
      @activity_params = {}.merge(params.permit(:source, :status))
      # :payload and :diagnostics may be a string or object
      @activity_params[:payload] = JSON.parse(request.body.read)["payload"]
      @activity_params[:diagnostics] = JSON.parse(request.body.read)["diagnostics"]
      @activity_params
    end

    def entry_update_params
      @activity_params = {}.merge(params.permit(:status, :duration_ms))
      @activity_params[:diagnostics] = JSON.parse(request.body.read)["diagnostics"]
      @activity_params
    end
end

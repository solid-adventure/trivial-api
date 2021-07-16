class WebhooksController < ApplicationController
    skip_before_action :authenticate_user!, only: [:create]
    before_action :authenticate_app_id!, only: [:stats]

    def index
        render json: webhooks
    end

    def create
        webhook = Webhook.new(webhook_params)
        webhook.user_id = App.find_by_name!(params[:app_id]).user_id
        if webhook.save
            render json: webhook, status: :created
        else
            render_bad_request webhook
        end
    end

    def show
        render json: webhook
    end

    def update
        if webhook.update(webhook_params)
            render json: webhook
        else
            render_bad_request webhook
        end
    end

    def send_new
      @app = current_user.apps.kept.find_by_name!(params[:id])
      res = Webhook.send_new @app, request.raw_post
      render json: {status: res.code.to_i, message: res.message}
    end

    def resend
        res = webhook.resend
        render json: {status: res.code.to_i, message: res.message}
    end

    def stats
        render json: Webhook.chart_stats(webhook_params[:app_id], 7)
    end

    def subscribe
      render json: Webhook.wait_for_newer(current_user, params[:app_id], params[:last_seen]).to_json
    end

    private

    def webhook
        @_webhook ||= current_user.webhooks.where(id: params[:id]).limit(1).first
    end

    def webhooks
        @_webhooks ||= current_user.webhooks.where(app_id: params[:app_id]).order(created_at: :desc)
    end

    def webhook_app_id
        @_webhook_app ||= Webhook.find_by(app_id: params[:app_id])
    end

    def webhook_params
        params.permit(:app_id, :payload, :source, :topic, :status, :diagnostics)
    end

    def authenticate_app_id!
        unless current_user.id == webhook_app_id.user_id
            render_unauthorized 'You do not have access to this webhook!'
        end
    end
end

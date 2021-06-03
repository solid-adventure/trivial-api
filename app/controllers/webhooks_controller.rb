class WebhooksController < ApplicationController
    skip_before_action :authenticate_user!, only: [:create, :stats]
    def index
        render json: webhooks
    end
    
    def create
        webhook = Webhook.new(webhook_params)
        webhook.user_id = Manifest.where(app_id: webhook_params[:app_id])&.last.user_id
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

    def stats
        render json: Webhook.get_chart_stats(webhook_params[:app_id])
    end

    private

    def webhook
        @_webhook ||= current_user.webhooks.where(id: params[:id]).limit(1).first
    end

    def webhooks
        @_webhooks ||= current_user.webhooks.where(app_id: params[:app_id])
        @_webhooks.reverse
    end

    def webhook_params
        params.permit(:app_id, :payload, :source, :topic, :status)
    end
end

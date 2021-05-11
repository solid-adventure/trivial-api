class WebhooksController < ApplicationController
    skip_before_action :authenticate_user!, only: [:show, :index, :create, :update]
    def index
        render json: webhooks
    end
    
    def create
        webhook = Webhook.new(webhook_params)
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

    private

    def webhook
        @_webhook ||= Webhook.find(params[:id])
    end

    def webhooks
        @_webhooks ||= Webhook.where(app_id: params[:app_id])
    end

    def webhook_params
        params.permit(:app_id, :user_id, :payload, :source, :topic)
    end
end

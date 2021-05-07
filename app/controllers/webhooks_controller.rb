class WebhooksController < ApplicationController
    def index
        render json: Webhook.where(app_id: params[:app_id])
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
        webhooks = Webhook.all
        render json: webhooks, include: []
    end

    def update
        if webhook.update(webhook_params)
            render json: webhook
        else
            render_bad_request webhook
        end
    end

    private

    # def webhooks

    # end

    def webhooks
        @_webhook ||= Webhook.where(app_id: params[:app_id])
    end

    def webhook_params
        params.permit(:app_id, :source)
    end
end

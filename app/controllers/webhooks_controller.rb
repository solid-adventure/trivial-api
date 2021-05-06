class WebhooksController < ApplicationController
    def index
        webhooks = Webhook.all
        render json: webhooks, include: []
    end
end

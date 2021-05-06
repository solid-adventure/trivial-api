class WebhooksController < ApplicationController
    def index
        render json: webhook, include: []
    end
end

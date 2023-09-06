class ManifestsController < ApplicationController

    load_and_authorize_resource

    def index
        render json: manifests, adapter: :attributes
    end

    def create
        manifest = Manifest.new(manifest_params.merge(app: app))
        manifest.user_id = current_user.id
        if manifest.save
            render json: manifest, adapter: :attributes, status: :created
        else
            render_bad_request manifest
        end
    end

    def show
        render json: manifest, adapter: :attributes
    end

    def update
        if manifest.update(manifest_params)
            render json: manifest, adapter: :attributes
        else
            render_bad_request manifest
        end
    end

    private

    def manifest
        # @manifest is already loaded and authorized
        @manifest
    end

    def manifests
        # @manifests is already loaded and authorized
        @manifests.where(app_id: params[:app_id]).order(created_at: :desc)
    end

    def manifest_params
        params.permit(:app_id, :content, :bundle)
    end

    def app
      @app ||= App.find_by_name(params[:app_id])
      authorize! :read, @app
    end

end

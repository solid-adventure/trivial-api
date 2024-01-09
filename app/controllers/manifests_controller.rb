class ManifestsController < ApplicationController

    def index
        render json: manifests, adapter: :attributes
    end

    def create
        manifest = Manifest.new(manifest_params.merge(app: app))
        manifest.owner = current_user
        if manifest.save
            render json: manifest, adapter: :attributes, status: :created
        else
            render_bad_request manifest
        end
    end

    def show
        authorize! :read, manifest
        render json: manifest, adapter: :attributes
    end

    def update
        authorize! :update, manifest
        if manifest.update(manifest_params)
            render json: manifest, adapter: :attributes
        else
            render_bad_request manifest
        end
    end

    private

    def manifest
        @manifest ||= Manifest.find(params[:id])
    end

    def manifests
        current_user.associated_manifests.where(app_id: params[:app_id]).order(created_at: :desc)
    end

    def manifest_params
        params.permit(:app_id, :content, :bundle)
    end

    def app
      @app ||= App.find_by_name(params[:app_id])
      authorize! :read, @app
    end
end

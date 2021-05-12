class ManifestsController < ApplicationController
    def index
        render json: manifests
    end
    
    def create
        manifest = Manifest.new(manifest_params)
        if manifest.save
            render json: manifest, status: :created
        else
            render_bad_request manifest
        end
    end

    def show
        render json: manifest
    end

    def update
        if manifest.update(manifest_params)
            render json: manifest
        else
            render_bad_request manifest
        end
    end

    private

    def manifest
        @_manifest ||= Manifest.find(params[:id])
    end

    def manifests
        @_manifests ||= Manifest.where(app_id: params[:app_id])
    end

    def manifest_params
        params.permit(:app_id, :content)
    end

end

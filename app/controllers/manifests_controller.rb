class ManifestsController < ApplicationController
    def index
        render json: manifests
    end

    def create
        manifest = Manifest.new(manifest_params)
        manifest.user_id = current_user.id
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
        @_manifest ||= current_user.manifests.where(id: params[:id]).limit(1).first
    end

    def manifests
        @_manifests ||= current_user.manifests.where(app_id: params[:app_id]).order(created_at: :desc)
    end

    def manifest_params
        params.permit(:app_id, :content)
    end

end

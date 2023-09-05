class ManifestsController < ApplicationController

    load_and_authorize_resource
    before_action :set_serializer_adapter


    def index
        render json: manifests
    end

    def create
        manifest = Manifest.new(manifest_params.merge(app: app))
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

    def set_serializer_adapter
        # Preserve behavior that preceeds the serializer
        ActiveModelSerializers.config.adapter = :attributes
    end

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

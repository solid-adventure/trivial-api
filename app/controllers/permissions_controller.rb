class PermissionsController < ApplicationController
  def index
    render json: { "permissions" => permissions }
  end

  def create
    perm = Permission.new(permission_params)
    perm.owner = current_user
    if perm.save
      render json: perm, status: :created
    else
      render_bad_request perm
    end
  end

  def update
    if permission.update(permission_params)
      render json: permission, status: :created
    else
      render_bad_request permission
    end
  end

  def show
    render json: { "permission" => permission }
  end

  def permissions
    current_user.permissions.map { |permission| permission.as_json }
  end

  def permission
    @permission ||= Permission.find(params[:id])
  end

  def permission_params
    params[:permission].permit(:name)
  end
end

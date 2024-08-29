class AuditsController < ApplicationController
  before_action :load_and_authorize_auditable
  before_action :load_and_authorize_audit, only: %i[show]
  before_action :set_pagination, only: %i[index]

  def index
    @audits = @auditable.own_and_associated_audits
    paginate_audits
    response = {
      current_page: @page,
      total_pages: @total_pages,
      audits: @audits.as_json(except: %i[user_type username audited_changes comment request_uuid])
    }

    render json: response, status: :ok
  end

  def show
    render json: @audit, root: :audit, status: :ok
  end

  private
  MAX_PER_PAGE = 100.freeze

  def load_and_authorize_auditable
    resource, id = request.path.split('/')[1,2]
    @auditable = resource.singularize.classify.constantize.find(id)

    raise CanCan::AccessDenied unless @auditable.admin?(current_user)
  end

  def load_and_authorize_audit
    @audit = Audited::Audit.find(params[:id])

    raise CanCan::AccessDenied unless @audit.auditable == @auditable || @audit.associated == @auditable
  end

  def set_pagination
    @per_page = params[:per_page] ? params[:per_page].to_i : MAX_PER_PAGE
    @per_page = [@per_page, MAX_PER_PAGE].min
    @page = params[:page] ? params[:page].to_i : 1
  end

  def paginate_audits
    raise 'invalid per_page param' unless @per_page.positive?
    raise 'invalid page param' unless @page.positive?

    @total_pages = (@audits.count.to_f / @per_page).ceil
    offset = (@page - 1) * @per_page
    @audits = @audits.limit(@per_page).offset(offset)
  end
end

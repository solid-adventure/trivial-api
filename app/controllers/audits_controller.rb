require 'csv'

class AuditsController < ApplicationController
  include Exportable
  self.export_serializer = OwnedAuditSerializer

  before_action :load_and_authorize_auditable
  before_action :load_and_filter_audits, only: %i[index csv]
  before_action :load_and_authorize_audit, only: %i[show]
  before_action :set_pagination, only: %i[index]

  def index
    if params[:format] == 'csv'
      handle_csv_export(collection: @audits)
    else
      paginate_audits
      response = {
        current_page: @page,
        total_pages: @total_pages,
        audits: ActiveModel::Serializer::CollectionSerializer.new(@audits)
      }

      render json: response, status: :ok
    end
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

  def load_and_filter_audits
    @audits = @auditable.all_audits
    filter_audits
  end

  def filter_audits
    search = params[:search] ? JSON.parse(params[:search]) : []
    if search.any?
      @audits = OwnedAudit.search(@audits, search)
    end
  end

  def load_and_authorize_audit
    @audit = Audited.audit_class.find(params[:id])

    raise CanCan::AccessDenied unless @audit.auditable == @auditable ||
      @audit.associated == @auditable ||
      @audit.owner == @auditable
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

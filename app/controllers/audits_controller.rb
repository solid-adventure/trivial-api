class AuditsController < ApplicationController
  before_action :load_and_authorize_auditable
  before_action :load_and_authorize_audit, only: %i[show]
  before_action :set_pagination, only: %i[index]

  def index
    @audits = @auditable.own_and_associated_audits.includes(:user)
    paginate_audits
    format_changes
    response = {
      current_page: @page,
      total_pages: @total_pages,
      audits: @audits.as_json(except: %i[user_type username comment request_uuid])
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

  def format_changes
    @audits = @audits.map do |audit|

      {
        id: audit.id,
        user_id: audit.user&.id,
        user_name: audit.user&.name || 'Unknown',
        user_email: audit.user&.email || 'Unknown',
        action: audit.action,
        associated_type: audit.associated_type,
        associated_id: audit.associated_id,
        auditable_type: audit.auditable_type,
        auditable_id: audit.auditable_id,
        created_at: audit.created_at,

        audited_changes: audit.audited_changes.map do |key, value|
          if key == 'content'
            Services::ManifestDiff.main(value.is_a?(Array) ? value[0] : nil, value.is_a?(Array) ? value[1] : value)
          else
            {
              attribute: key,
              humanized_attribute: key, # adding for consistency with ManifestDiff output
              new_value: value.is_a?(Array) ? value[1] : value,
              old_value: value.is_a?(Array) ? value[0] : nil
            }
          end
        end.flatten
      }
    end
  end

end

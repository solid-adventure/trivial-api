class AuditsController < ApplicationController
  before_action :load_and_authorize_auditable
  before_action :load_and_authorize_audit, only: %i[show]
  before_action :set_pagination, only: %i[index]

  def index
    @audits = @auditable.own_and_associated_audits.includes(:user).order(created_at: :desc)
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

    puts "@auditable: #{@auditable.inspect}"

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

  def pretty_json_diff?(auditable_type, key)
    auditable_type == 'Manifest' && key == 'content' ||
    auditable_type == 'Register' && key == 'meta'
  end

  def reference_name(audit)
    audit.associated.respond_to?(:descriptive_name) && audit.associated&.descriptive_name ||
    audit.auditable.respond_to?(:descriptive_name) && audit.auditable&.descriptive_name ||
    audit.auditable.respond_to?(:name) && audit.auditable&.name ||
    'Not provided'
  end

  def format_changes
    @audits = @audits.map do |audit|

      {
        id: audit.id,
        user_id: audit.user&.id,
        user_name: audit.user&.name || 'Not provided',
        user_email: audit.user&.email || 'Not provided',
        action: audit.action,
        reference_type: audit.associated_type || audit.auditable_type,
        reference_id: audit.associated_id || audit.auditable_id,
        reference_name: reference_name(audit),
        created_at: audit.created_at,
        audited_changes: audit.audited_changes.map do |key, value|

          if pretty_json_diff? audit.auditable_type, key
            {
              attribute: key,
              patch: Manifest.json_patch(*value),
              old_value: value.is_a?(Array) ? value[0] : nil,
              new_value: value.is_a?(Array) ? value[1] : value
            }
          elsif audit.auditable_type == 'User' && key == 'tokens'
            {
              attribute: key,
              patch: "Log In / Out"
              old_value: value.is_a?(Array) ? value[0] : nil,
              new_value: value.is_a?(Array) ? value[1] : value
            }
          elsif value.is_a?(Array)
            {
              attribute: key,
              patch: "- #{key}: #{value[0]}\n+ #{key}: #{value[1]}",
              old_value: value.is_a?(Array) ? value[0] : nil,
              new_value: value.is_a?(Array) ? value[1] : value
            }
          else
            {
              attribute: key,
              patch: "#{key}: #{value}",
              old_value: value.is_a?(Array) ? value[0] : nil,
              new_value: value.is_a?(Array) ? value[1] : value
            }
          end

        end.flatten
      }
    end
  end

end

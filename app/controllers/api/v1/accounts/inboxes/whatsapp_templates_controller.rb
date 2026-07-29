class Api::V1::Accounts::Inboxes::WhatsappTemplatesController < Api::V1::Accounts::BaseController
  TEMPLATE_COMPONENT_KEYS = {
    'HEADER' => %w[type format text example],
    'BODY' => %w[type text example],
    'FOOTER' => %w[type text]
  }.freeze
  TEMPLATE_RESPONSE_KEYS = %w[
    id
    name
    language
    status
    category
    components
    namespace
    rejected_reason
    sub_category
    parameter_format
  ].freeze

  before_action :fetch_inbox
  before_action :validate_whatsapp_inbox
  before_action :authorize_template_access, only: [:index]
  before_action :authorize_template_update, only: [:create, :destroy]
  before_action :validate_whatsapp_cloud_provider, only: [:create, :destroy]

  def index
    log_template_info('Fetch requested', action: 'index')
    templates = fetch_and_format_templates
    log_template_info('Fetch succeeded', action: 'index', template_count: templates.length)
    render json: templates
  rescue StandardError => e
    log_template_error('Fetch failed', action: 'index', error: e.message)
    render json: { error: 'Failed to fetch templates' }, status: :internal_server_error
  end

  def create
    payload = template_payload
    log_template_info('Create requested', action: 'create', template_name: payload['name'], category: payload['category'])

    response = @inbox.channel.create_template(payload)
    schedule_template_sync
    render_created_template(payload, response)
  rescue Whatsapp::Providers::WhatsappCloudService::TemplateRequestTimeoutError => e
    schedule_template_sync_after_timeout(action: 'create', template_name: params[:name])
    render json: { errors: [e.message] }, status: :unprocessable_entity
  rescue StandardError => e
    log_template_error('Create failed', action: 'create', template_name: params[:name], error: e.message)
    render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  def destroy
    log_template_info('Delete requested', action: 'destroy', template_name: params[:id])
    @inbox.channel.delete_template(params[:id])
    schedule_template_sync
    log_template_info('Delete succeeded', action: 'destroy', template_name: params[:id])
    head :no_content
  rescue Whatsapp::Providers::WhatsappCloudService::TemplateRequestTimeoutError => e
    schedule_template_sync_after_timeout(action: 'destroy', template_name: params[:id])
    render json: { errors: [e.message] }, status: :unprocessable_entity
  rescue StandardError => e
    log_template_error('Delete failed', action: 'destroy', template_name: params[:id], error: e.message)
    render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def validate_whatsapp_inbox
    return if @inbox.channel_type == 'Channel::Whatsapp'

    render json: { error: 'Inbox is not a WhatsApp inbox' }, status: :bad_request
  end

  def authorize_template_access
    authorize @inbox, :show?
  end

  def authorize_template_update
    authorize @inbox, :update?
  end

  def validate_whatsapp_cloud_provider
    return if @inbox.channel.provider == 'whatsapp_cloud'

    render json: { errors: ['provider_not_supported'] }, status: :unprocessable_entity
  end

  def fetch_and_format_templates
    raw_templates = @inbox.channel.message_templates || {}
    format_templates(raw_templates)
  end

  def format_templates(templates)
    return [] if templates.blank?

    # Templates can be stored as array or hash depending on provider
    template_array = templates.is_a?(Array) ? templates : templates.values.flatten

    # Ensure we have an array of hashes
    template_array.select { |t| t.is_a?(Hash) }.map { |template| format_template(template) }
  end

  def format_template(template)
    normalized_template = template.with_indifferent_access

    TEMPLATE_RESPONSE_KEYS.each_with_object({}) do |key, payload|
      payload[key.to_sym] = normalized_template[key]
    end
  end

  def build_created_template(payload, provider_response)
    normalized_payload = payload.with_indifferent_access
    normalized_provider_response = provider_response.respond_to?(:with_indifferent_access) ? provider_response.with_indifferent_access : {}

    {
      id: normalized_provider_response[:id],
      name: normalized_provider_response[:name] || normalized_payload[:name],
      language: normalized_provider_response[:language] || normalized_payload[:language],
      status: normalized_provider_response[:status] || 'PENDING',
      category: normalized_provider_response[:category] || normalized_payload[:category],
      components: normalized_provider_response[:components] || normalized_payload[:components],
      namespace: normalized_provider_response[:namespace],
      rejected_reason: normalized_provider_response[:rejected_reason],
      sub_category: normalized_provider_response[:sub_category],
      parameter_format: normalized_provider_response[:parameter_format]
    }
  end

  def template_payload
    payload = params.permit(:name, :language, :category).to_h
    payload['components'] = permitted_components
    payload
  end

  def permitted_components
    Array(params[:components]).filter_map do |component|
      permitted_component(component)
    end
  end

  def permitted_component(component)
    component = component.to_unsafe_h if component.respond_to?(:to_unsafe_h)
    component_type = component['type'].to_s.upcase
    return permitted_buttons_component(component) if component_type == 'BUTTONS'
    return unless TEMPLATE_COMPONENT_KEYS.key?(component_type)

    component.slice(*TEMPLATE_COMPONENT_KEYS[component_type]).merge('type' => component_type)
  end

  def permitted_buttons_component(component)
    permitted_buttons = permitted_template_buttons(component['buttons'])
    { 'type' => 'BUTTONS', 'buttons' => permitted_buttons } if permitted_buttons.present?
  end

  def permitted_template_buttons(buttons)
    Array(buttons).filter_map do |button|
      button = button.to_unsafe_h if button.respond_to?(:to_unsafe_h)
      button_type = button['type'].to_s.upcase
      next unless %w[QUICK_REPLY URL COPY_CODE].include?(button_type)

      button.slice('type', 'text', 'url', 'example').merge('type' => button_type)
    end
  end

  def template_log_context(extra = {})
    {
      account_id: Current.account.id,
      inbox_id: @inbox.id,
      channel_id: @inbox.channel.id,
      provider: @inbox.channel.provider
    }.merge(extra).compact
  end

  def log_template_info(message, extra = {})
    Rails.logger.info("[WHATSAPP TEMPLATES] #{message} #{template_log_context(extra).to_json}")
  end

  def log_template_error(message, extra = {})
    Rails.logger.error("[WHATSAPP TEMPLATES] #{message} #{template_log_context(extra).to_json}")
  end

  def render_created_template(payload, response)
    created_template = format_template(build_created_template(payload, response))
    log_template_info(
      'Create succeeded',
      action: 'create',
      template_name: created_template[:name],
      template_id: created_template[:id],
      template_status: created_template[:status]
    )
    render json: created_template
  end

  def schedule_template_sync
    Channels::Whatsapp::TemplatesSyncJob.perform_later(@inbox.channel)
  end

  def schedule_template_sync_after_timeout(action:, template_name:)
    schedule_template_sync
    log_template_info('Sync scheduled after timeout', action: action, template_name: template_name)
  end
end

class Api::V1::Accounts::Inboxes::WhatsappTemplatesController < Api::V1::Accounts::BaseController
  TEMPLATE_COMPONENT_KEYS = {
    'HEADER' => %w[type format text example],
    'BODY' => %w[type text example],
    'FOOTER' => %w[type text]
  }.freeze

  before_action :fetch_inbox
  before_action :validate_whatsapp_inbox
  before_action :authorize_template_access, only: [:index]
  before_action :authorize_template_update, only: [:create, :destroy]
  before_action :validate_whatsapp_cloud_provider, only: [:create, :destroy]

  def index
    templates = fetch_and_format_templates
    render json: templates
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP TEMPLATES] Failed to fetch templates: #{e.message}"
    render json: { error: 'Failed to fetch templates' }, status: :internal_server_error
  end

  def create
    response = @inbox.channel.create_template(template_payload)
    Channels::Whatsapp::TemplatesSyncJob.perform_later(@inbox.channel)
    render json: response
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP TEMPLATES] Failed to create template: #{e.message}"
    render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  def destroy
    @inbox.channel.delete_template(params[:id])
    Channels::Whatsapp::TemplatesSyncJob.perform_later(@inbox.channel)
    head :no_content
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP TEMPLATES] Failed to delete template: #{e.message}"
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
    template_array.select { |t| t.is_a?(Hash) }.map do |template|
      {
        id: template['id'],
        name: template['name'],
        language: template['language'],
        status: template['status'],
        category: template['category'],
        components: template['components'],
        namespace: template['namespace']
      }
    end
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
end

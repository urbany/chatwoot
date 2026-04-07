class Api::V1::Accounts::Inboxes::WhatsappTemplatesController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :validate_whatsapp_inbox
  before_action :authorize_template_access

  def index
    templates = fetch_and_format_templates
    render json: templates
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP TEMPLATES] Failed to fetch templates: #{e.message}"
    render json: { error: 'Failed to fetch templates' }, status: :internal_server_error
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
end

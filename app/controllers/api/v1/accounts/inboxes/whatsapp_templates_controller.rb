class Api::V1::Accounts::Inboxes::WhatsappTemplatesController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :validate_whatsapp_inbox

  def index
    @templates = @inbox.channel.message_templates || {}
    render json: format_templates(@templates)
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def validate_whatsapp_inbox
    return if @inbox.channel_type == 'Channel::Whatsapp'

    render_not_found_error('Inbox is not a WhatsApp inbox')
  end

  def format_templates(templates)
    return [] if templates.blank?

    # Templates can be stored as array or hash depending on provider
    template_array = templates.is_a?(Array) ? templates : templates.values.flatten

    template_array.map do |template|
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

class MessageTemplates::Template::CsatSurvey
  pattr_initialize [:conversation!]

  def perform
    ActiveRecord::Base.transaction do
      conversation.messages.create!(csat_survey_message_params)
    end
  end

  private

  delegate :contact, :account, :inbox, to: :conversation

  def message_content
    return I18n.t('conversations.templates.csat_input_message_body') if csat_config.blank? || csat_config['message'].blank?

    csat_config['message']
  end

  def csat_survey_message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content_type: :input_csat,
      content: message_content,
      content_attributes: content_attributes
    }
  end

  def csat_config
    inbox.csat_config || {}
  end

  def content_attributes
    attrs = {
      display_type: csat_config['display_type'] || 'emoji'
    }
    attrs[:items] = csat_items if inbox.whatsapp?
    attrs
  end

  def csat_items
    [
      { title: '1', value: '1' },
      { title: '2', value: '2' },
      { title: '3', value: '3' },
      { title: '4', value: '4' },
      { title: '5', value: '5' }
    ]
  end
end

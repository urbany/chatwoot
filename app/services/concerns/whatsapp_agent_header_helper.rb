module WhatsappAgentHeaderHelper
  def whatsapp_agent_header_content(content:, sender:, format: :channel)
    message_content = content.to_s
    sender_name = sender.try(:available_name).presence || sender&.name.presence
    return message_content if sender_name.blank?
    return message_content if whatsapp_agent_header_present?(message_content, sender_name)

    header = whatsapp_agent_header(sender_name, format)
    return header if message_content.blank?

    "#{header}\n#{message_content}"
  end

  def whatsapp_storage_agent_header_content(content:, sender:)
    whatsapp_agent_header_content(content: content, sender: sender, format: :storage)
  end

  def whatsapp_ui_agent_header_enabled?(message_type:, echo_id:, private:, sender:, inbox:)
    message_type == 'outgoing' && echo_id.present? && !private && sender.is_a?(User) && (inbox.whatsapp? || inbox.twilio_whatsapp?)
  end

  # rubocop:disable Metrics/ParameterLists
  def whatsapp_agent_header_payload(content:, content_attributes:, message_type:, echo_id:, private:, sender:, inbox:)
    enabled = whatsapp_ui_agent_header_enabled?(
      message_type: message_type,
      echo_id: echo_id,
      private: private,
      sender: sender,
      inbox: inbox
    )

    {
      content: enabled ? whatsapp_storage_agent_header_content(content: content, sender: sender) : content,
      content_attributes: enabled ? content_attributes.merge(whatsapp_agent_header_enabled: true) : content_attributes
    }
  end
  # rubocop:enable Metrics/ParameterLists

  private

  def whatsapp_agent_header_present?(message_content, sender_name)
    [:channel, :storage].any? do |format|
      header = whatsapp_agent_header(sender_name, format)
      message_content == header || message_content.start_with?("#{header}\n")
    end
  end

  def whatsapp_agent_header(sender_name, format)
    format == :storage ? "**#{sender_name}:**" : "*#{sender_name}:*"
  end
end

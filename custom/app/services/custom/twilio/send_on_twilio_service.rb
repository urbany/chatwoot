# Prepended into Twilio::SendOnTwilioService via a one-time `prepend_mod_with`
# hook added to the OSS file (it had none upstream).
module Custom::Twilio::SendOnTwilioService
  include WhatsappAgentHeaderHelper

  private

  def message_params
    {
      body: outgoing_body,
      to: contact_inbox.source_id,
      media_url: attachments
    }
  end

  def outgoing_body
    content = message.outgoing_content.to_s
    return content unless whatsapp_agent_header_enabled?

    whatsapp_agent_header_content(content: content, sender: message.sender)
  end

  def whatsapp_agent_header_enabled?
    return false unless channel.whatsapp?

    content_attributes = message.content_attributes.with_indifferent_access
    additional_attributes = message.additional_attributes.with_indifferent_access

    ActiveModel::Type::Boolean.new.cast(content_attributes['whatsapp_agent_header_enabled']) &&
      message.sender.is_a?(User) &&
      content_attributes['automation_rule_id'].blank? &&
      content_attributes['external_echo'].blank? &&
      additional_attributes['campaign_id'].blank?
  end
end

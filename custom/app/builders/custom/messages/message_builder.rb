# Prepended into Messages::MessageBuilder via the OSS file's existing
# `prepend_mod_with('Messages::MessageBuilder')` call — no edits needed
# on the upstream file itself.
module Custom::Messages::MessageBuilder
  include WhatsappAgentHeaderHelper

  private

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def message_params
    message_type_value = message_type
    message_sender = sender
    sanitized_content_attributes = content_attributes.except(:whatsapp_agent_header_enabled, 'whatsapp_agent_header_enabled')
    whatsapp_header_payload = if @params[:template_params].present?
                                {
                                  content: @params[:content],
                                  content_attributes: sanitized_content_attributes
                                }
                              else
                                whatsapp_agent_header_payload(
                                  content: @params[:content],
                                  content_attributes: content_attributes,
                                  message_type: message_type_value,
                                  private: @private,
                                  sender: message_sender,
                                  inbox: @conversation.inbox
                                )
                              end

    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: message_type_value,
      content: whatsapp_header_payload[:content],
      private: @private,
      sender: message_sender,
      content_type: @params[:content_type],
      content_attributes: whatsapp_header_payload[:content_attributes].presence,
      items: @items,
      in_reply_to: @in_reply_to,
      echo_id: @params[:echo_id],
      source_id: @params[:source_id]
    }.merge(external_created_at).merge(automation_rule_id).merge(campaign_id).merge(template_params)
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end

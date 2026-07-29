# Prepended into Whatsapp::Providers::BaseService via a one-time
# `prepend_mod_with` hook added to the OSS file (it had none upstream).
module Custom::Whatsapp::Providers::BaseService
  include WhatsappAgentHeaderHelper

  def send_reaction(_phone_number, _message_id, _emoji)
    raise 'Overwrite this method in child class'
  end

  def create_template(_payload)
    raise 'Overwrite this method in child class'
  end

  def delete_template(_name)
    raise 'Overwrite this method in child class'
  end

  # -- Overrides: swap message.outgoing_content for the agent-header-aware
  #    whatsapp_outgoing_content everywhere a button/list payload is built --

  def create_button_payload(message)
    buttons = create_buttons(message.content_attributes['items'])
    json_hash = { 'buttons' => buttons }
    create_payload('button', whatsapp_outgoing_content(message), JSON.generate(json_hash))
  end

  def create_list_payload(message)
    rows = create_rows(message.content_attributes['items'])
    section1 = { 'rows' => rows }
    sections = [section1]
    json_hash = { :button => I18n.t('conversations.messages.whatsapp.list_button_label'), 'sections' => sections }
    create_payload('list', whatsapp_outgoing_content(message), JSON.generate(json_hash))
  end

  def whatsapp_outgoing_content(message)
    content = message.outgoing_content.to_s
    return content unless whatsapp_agent_header_enabled?(message)

    whatsapp_agent_header_content(content: content, sender: message.sender)
  end

  def whatsapp_agent_header_enabled?(message)
    content_attributes = message.content_attributes.with_indifferent_access
    additional_attributes = message.additional_attributes.with_indifferent_access

    ActiveModel::Type::Boolean.new.cast(content_attributes['whatsapp_agent_header_enabled']) &&
      message.sender.is_a?(User) &&
      content_attributes['automation_rule_id'].blank? &&
      content_attributes['external_echo'].blank? &&
      additional_attributes['campaign_id'].blank?
  end
end

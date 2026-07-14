# Prepended into Whatsapp::IncomingMessageServiceHelpers via a one-time
# `prepend_mod_with` hook added to the OSS file (it had none upstream).
# This is a plain helpers module (all public), included into
# Whatsapp::IncomingMessageBaseService and the provider-specific incoming
# message services — prepending here flows through to all of them.
module Custom::Whatsapp::IncomingMessageServiceHelpers
  def unprocessable_message_type?(message_type)
    %w[ephemeral unsupported request_welcome].include?(message_type)
  end

  def reaction_message?(message)
    message[:type] == 'reaction' || message['type'] == 'reaction'
  end

  def reaction_target_message(reaction)
    message_id = reaction[:message_id] || reaction['message_id']
    return if message_id.blank?

    inbox.messages.find_by(source_id: message_id)
  end

  def reaction_actor_name(target_message)
    processed_params.dig(:contacts, 0, :profile, :name).presence ||
      processed_params.dig('contacts', 0, 'profile', 'name').presence ||
      target_message.conversation.contact&.name
  end

  def reaction_metadata(message)
    {
      wa_id: processed_waid(message[:from] || message['from']),
      reaction_source_id: (message[:id] || message['id']).to_s.presence,
      updated_at: reaction_timestamp(message)
    }.compact
  end

  def reaction_timestamp(message)
    timestamp = message[:timestamp] || message['timestamp']
    return if timestamp.blank?

    Time.zone.at(timestamp.to_i).iso8601
  end
end

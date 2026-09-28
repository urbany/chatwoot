# Prepended into Whatsapp::IncomingMessageBaseService via a one-time
# `prepend_mod_with` hook added to the OSS file (it had none upstream).
module Custom::Whatsapp::IncomingMessageBaseService
  private

  # Guard added ahead of the original method: reactions get routed to
  # ReactionUpdateService and return early; everything else falls through
  # to the unchanged upstream body via `super`.
  def process_messages
    return process_reaction_message(messages_data.first) if reaction_message?(messages_data.first)

    super
  end

  def process_reaction_message(message)
    reaction = message[:reaction] || message['reaction']
    return if reaction.blank?

    target_message = reaction_target_message(reaction)
    return if target_message.blank?

    Messages::ReactionUpdateService.new(
      message: target_message,
      actor_key: 'contact',
      actor: {
        type: 'contact',
        id: target_message.conversation.contact_id,
        name: reaction_actor_name(target_message)
      },
      emoji: reaction[:emoji] || reaction['emoji'],
      metadata: reaction_metadata(message)
    ).perform
  end
end

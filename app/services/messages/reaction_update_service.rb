class Messages::ReactionUpdateService
  attr_reader :message, :actor_key, :actor_type, :actor_id, :actor_name, :emoji, :metadata

  def initialize(message:, actor_key:, actor_type:, actor_id: nil, actor_name: nil, emoji:, metadata: {})
    @message = message
    @actor_key = actor_key
    @actor_type = actor_type
    @actor_id = actor_id
    @actor_name = actor_name
    @emoji = emoji
    @metadata = metadata
  end

  def perform
    updated_attributes = current_content_attributes
    updated_reactions = current_reactions

    if emoji.present?
      updated_reactions[actor_key] = reaction_payload
    else
      updated_reactions.delete(actor_key)
    end

    if updated_reactions.present?
      updated_attributes[:reactions] = updated_reactions
    else
      updated_attributes.delete(:reactions)
    end

    normalized_attributes = updated_attributes.to_h.deep_stringify_keys
    return message if normalized_attributes == normalized_content_attributes

    message.update!(content_attributes: normalized_attributes)
    message
  end

  private

  def current_content_attributes
    (message.content_attributes || {}).deep_dup.with_indifferent_access
  end

  def current_reactions
    reactions = current_content_attributes[:reactions]
    return {}.with_indifferent_access unless reactions.is_a?(Hash)

    reactions.deep_dup.with_indifferent_access
  end

  def normalized_content_attributes
    (message.content_attributes || {}).deep_stringify_keys
  end

  def reaction_payload
    {
      actor_type: actor_type,
      actor_id: actor_id,
      actor_name: actor_name,
      emoji: emoji
    }.merge(metadata).compact.deep_stringify_keys
  end
end
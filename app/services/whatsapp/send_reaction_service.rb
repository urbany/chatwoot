class Whatsapp::SendReactionService
  EMOJI_REQUIRED_ERROR = 'Emoji is required'.freeze
  UNSUPPORTED_INBOX_ERROR = 'Message reactions are only supported for WhatsApp Cloud inboxes'.freeze
  TARGET_MESSAGE_ERROR = 'You can only react to incoming WhatsApp user messages'.freeze
  SOURCE_ID_ERROR = 'This message cannot be reacted to because it has no WhatsApp source ID'.freeze
  CONTACT_PHONE_ERROR = 'This conversation cannot be reacted to because the contact phone number is missing'.freeze
  MESSAGE_WINDOW_ERROR = 'You can only react within the 24-hour WhatsApp reply window'.freeze

  attr_reader :message, :user, :emoji

  def initialize(message:, user:, emoji:)
    @message = message
    @user = user
    @emoji = emoji
  end

  def perform
    validate!

    reaction_source_id = channel.send_reaction(contact_phone_number, message.source_id, emoji)

    Messages::ReactionUpdateService.new(
      message: message,
      actor_key: 'business',
      actor: { type: 'business', id: user&.id, name: actor_name },
      emoji: emoji,
      metadata: {
        reaction_source_id: reaction_source_id,
        updated_at: Time.zone.now.iso8601
      }
    ).perform
  end

  private

  def validate!
    raise StandardError, EMOJI_REQUIRED_ERROR if emoji.blank?
    raise StandardError, UNSUPPORTED_INBOX_ERROR unless whatsapp_cloud_channel?
    raise StandardError, TARGET_MESSAGE_ERROR unless target_message_valid?
    raise StandardError, SOURCE_ID_ERROR if message.source_id.blank?
    raise StandardError, CONTACT_PHONE_ERROR if contact_phone_number.blank?
    raise StandardError, MESSAGE_WINDOW_ERROR unless message.conversation.can_reply?
  end

  def whatsapp_cloud_channel?
    channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'
  end

  def target_message_valid?
    message.incoming? && !message.private? && message.deleted.blank? && !message.activity?
  end

  def contact_phone_number
    @contact_phone_number ||= message.conversation.contact_inbox&.source_id
  end

  def channel
    @channel ||= message.conversation.inbox.channel
  end

  def actor_name
    user&.name
  end
end

class CsatSurveys::InlineProcessor
  pattr_initialize [:message!]

  def perform
    return unless processable?

    csat_message = find_pending_csat_message
    return if csat_message.blank?

    create_csat_response(csat_message)
  end

  private

  def processable?
    message.incoming? && message.content.present? && message.content.match?(/\A[1-5]\z/)
  end

  def find_pending_csat_message
    conversation.messages
                .where(content_type: :input_csat)
                .where.missing(:csat_survey_response)
                .reorder(created_at: :desc)
                .first
  end

  def create_csat_response(csat_message)
    CsatSurveyResponse.create!(
      message_id: csat_message.id,
      account_id: message.account_id,
      conversation_id: message.conversation_id,
      contact_id: contact.id,
      assigned_agent: conversation.assignee,
      rating: message.content.to_i
    )
  end

  def conversation
    message.conversation
  end

  def contact
    conversation.contact
  end
end

CsatSurveys::InlineProcessor.prepend_mod_with('CsatSurveys::InlineProcessor')

# Prepended into Api::V1::Accounts::Conversations::MessagesController via a
# one-time `prepend_mod_with` hook added to the OSS file (it had none
# upstream).
module Custom::Api::V1::Accounts::Conversations::MessagesController
  def reaction
    actor = Current.user || @resource
    @message = Whatsapp::SendReactionService.new(message: message, user: actor, emoji: permitted_params[:emoji]).perform
    render :update
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  private

  def permitted_params
    params.permit(:id, :target_language, :status, :external_error, :emoji)
  end
end

# Prepended into Api::V1::Accounts::Concerns::WhatsappHealthManagement via a
# one-time `prepend_mod_with` hook added to the OSS file (it had none
# upstream). Since this is a concern `include`d into a controller, prepending
# it here still flows through to any controller that includes the concern.
module Custom::Api::V1::Accounts::Concerns::WhatsappHealthManagement
  def sync_templates
    return render status: :unprocessable_entity, json: { error: 'Template sync is only available for WhatsApp channels' } unless whatsapp_channel?

    log_template_info('Manual sync requested', action: 'manual_sync')
    trigger_template_sync
    log_template_info('Manual sync enqueued', action: 'manual_sync')
    render status: :ok, json: { message: 'Template sync initiated successfully' }
  rescue StandardError => e
    log_template_error('Manual sync failed', action: 'manual_sync', error: e.message)
    render status: :internal_server_error, json: { error: e.message }
  end

  private

  def template_log_context(extra = {})
    {
      account_id: Current.account.id,
      inbox_id: @inbox.id,
      channel_id: @inbox.channel.id,
      provider: @inbox.channel.provider
    }.merge(extra).compact
  end

  def log_template_info(message, extra = {})
    Rails.logger.info("[WHATSAPP TEMPLATES] #{message} #{template_log_context(extra).to_json}")
  end

  def log_template_error(message, extra = {})
    Rails.logger.error("[WHATSAPP TEMPLATES] #{message} #{template_log_context(extra).to_json}")
  end
end

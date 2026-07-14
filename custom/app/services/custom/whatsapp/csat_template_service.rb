# Prepended into Whatsapp::CsatTemplateService via a one-time
# `prepend_mod_with` hook added to the OSS file (it had none upstream).
module Custom::Whatsapp::CsatTemplateService
  def delete_template(template_name = nil)
    template_name ||= CsatTemplateNameService.csat_template_name(@whatsapp_channel.inbox.id)
    response = @whatsapp_channel.delete_template(template_name)
    { success: true, response_body: response.body }
  rescue StandardError => e
    Rails.logger.error "WhatsApp template deletion failed: #{e.message}"
    { success: false, response_body: e.message }
  end

  private

  def send_template_creation_request(request_body)
    @whatsapp_channel.provider_service.send(:post_message_template, request_body)
  end
end

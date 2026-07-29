# rubocop:disable Metrics/ModuleLength
# Prepended into Whatsapp::Providers::WhatsappCloudService via the OSS file's existing
# `prepend_mod_with('Whatsapp::Providers::WhatsappCloudService')` call — no edits needed
# on the upstream file itself.
module Custom::Whatsapp::Providers::WhatsappCloudService
  class TemplateRequestTimeoutError < RuntimeError; end

  TEMPLATE_REQUEST_TIMEOUT = 10
  TEMPLATE_RECOVERY_TIMEOUT = 3
  TEMPLATE_REQUEST_TIMEOUT_MESSAGE = 'WhatsApp API request timed out. Template state will sync shortly.'.freeze
  REACTION_REQUEST_TIMEOUT = 10
  REACTION_REQUEST_TIMEOUT_MESSAGE = 'WhatsApp API request timed out while sending a reaction. Please try again.'.freeze
  INVALID_REACTION_TARGET_ERROR_CODE = 131_009
  INVALID_REACTION_TARGET_MESSAGE = 'This message can no longer receive reactions.'.freeze

  # -- New capabilities (no upstream equivalent) ---------------------------

  def send_reaction(phone_number, message_id, emoji)
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: reaction_request_body(phone_number, message_id, emoji).to_json,
      timeout: REACTION_REQUEST_TIMEOUT
    )

    parsed_response = response.parsed_response
    return parsed_response['messages'].first['id'] if response.success? && parsed_response['error'].blank?

    raise reaction_error_message(response)
  rescue Net::OpenTimeout, Net::ReadTimeout
    raise REACTION_REQUEST_TIMEOUT_MESSAGE.to_s
  end

  def create_template(payload)
    template_name = template_name(payload)
    log_template_info(
      'Create requested',
      action: 'create_template',
      template_name: template_name,
      category: template_category(payload)
    )

    response = post_message_template(payload)
    return created_template_response(response, template_name) if response.success?

    raise_create_template_error(response, template_name)
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    recover_created_template(template_name, e)
  end

  def delete_template(template_name)
    log_template_info('Delete requested', action: 'delete_template', template_name: template_name)

    response = delete_message_template(template_name)
    if response.success?
      log_template_info('Delete succeeded', action: 'delete_template', template_name: template_name)
      return response
    end

    raise_delete_template_error(response, template_name)
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    handle_delete_template_timeout(template_name, e)
  end

  # -- Overrides of upstream behavior (full replace: logic changed too much
  #    for a clean `super` call; treat these as the source of truth) --------

  def sync_templates
    log_template_info('Sync started', action: 'sync_templates', request_url: message_templates_path)

    # ensuring that channels with wrong provider config wouldn't keep trying to sync templates
    whatsapp_channel.mark_message_templates_updated
    templates = fetch_whatsapp_templates(message_templates_path)
    update_result = whatsapp_channel.update(message_templates: templates, message_templates_last_updated: Time.now.utc) if templates.present?

    log_template_info('Sync completed', action: 'sync_templates', template_count: templates.length)

    update_result
  rescue StandardError => e
    log_template_error('Sync failed', action: 'sync_templates', error: e.message)
    raise
  end

  def fetch_whatsapp_templates(url, page: 1)
    response = HTTParty.get(url, headers: api_headers)
    return handle_template_fetch_failure(response, url, page) unless response.success?

    templates = response['data'] || []
    next_page_url = next_url(response)

    log_template_info(
      'Template page fetched',
      action: 'fetch_templates',
      page: page,
      request_url: url,
      fetched_count: templates.length,
      has_next_page: next_page_url.present?
    )

    return templates + fetch_whatsapp_templates(next_page_url, page: page + 1) if next_page_url.present?

    templates
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    log_template_error('Template fetch timed out', action: 'fetch_templates', page: page, request_url: url, error: e.message)
    raise
  end

  def validate_provider_config?
    response = HTTParty.get(message_templates_path, headers: api_headers)
    return waba_or_token_check_failure(response) unless response.success?

    # The templates check only proves the WABA/token pair, so verify the phone_number_id belongs to this WABA when it changes.
    return true unless whatsapp_channel.provider_config_changed?

    validate_phone_number_id
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    log_template_error('Provider config validation timed out', action: 'validate_provider_config', error: e.message)
    raise
  end

  private

  def waba_or_token_check_failure(response)
    log_template_error(
      'Provider config validation failed',
      action: 'validate_provider_config',
      error: template_response_error(response),
      error_payload: template_error_payload(response)
    )
    log_transfer_failure('waba_or_token_check', response)
  end

  def validate_phone_number_id
    phone_response = HTTParty.get("#{business_account_path}/phone_numbers?fields=id&limit=100", headers: api_headers)
    ids = phone_response.parsed_response.is_a?(Hash) ? Array(phone_response.parsed_response['data']) : []
    return true if phone_response.success? && ids.any? { |number| number['id'] == whatsapp_channel.provider_config['phone_number_id'].to_s }

    log_template_error(
      'Provider config validation failed: phone_number_id mismatch',
      action: 'validate_provider_config',
      error_payload: template_error_payload(phone_response)
    )
    log_transfer_failure('phone_number_id_check', phone_response)
  end

  # -- Overrides of upstream private methods (full replace) ----------------

  def send_text_message(phone_number, message)
    outgoing_content = whatsapp_outgoing_content(message)

    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        context: whatsapp_reply_context(message),
        to: phone_number,
        text: { body: outgoing_content },
        type: 'text'
      }.to_json
    )
    process_response(response, message)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    normalize_opus_content_type(attachment)
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    outgoing_content = whatsapp_outgoing_content(message)
    type_content = build_attachment_content(type, attachment, outgoing_content)
    response = HTTParty.post(
      "#{phone_id_path('v24.0')}/messages",
      headers: api_headers,
      body: {
        :messaging_product => 'whatsapp',
        :context => whatsapp_reply_context(message),
        :to => phone_number,
        :type => type,
        type.to_s => type_content
      }.to_json
    )
    process_response(response, message)
  end

  def build_attachment_content(type, attachment, outgoing_content)
    type_content = { 'link' => attachment.download_url }
    type_content['caption'] = outgoing_content unless %w[audio sticker].include?(type)
    type_content['filename'] = attachment.file.filename if type == 'document'
    type_content['voice'] = true if voice_message?(type, attachment)
    type_content
  end

  # -- Private helpers backing the above ------------------------------------

  def message_templates_path
    "#{business_account_path}/message_templates"
  end

  def post_message_template(body)
    HTTParty.post(
      message_templates_path,
      headers: api_headers,
      body: body.to_json,
      timeout: TEMPLATE_REQUEST_TIMEOUT
    )
  end

  def delete_message_template(template_name)
    HTTParty.delete(
      "#{message_templates_path}?name=#{template_name}",
      headers: api_headers,
      timeout: TEMPLATE_REQUEST_TIMEOUT
    )
  end

  def parsed_template_response(response)
    return response.parsed_response if response.respond_to?(:parsed_response) && response.parsed_response.present?

    response
  end

  def created_template_response(response, template_name)
    template_response = parsed_template_response(response)
    log_template_info(
      'Create succeeded',
      action: 'create_template',
      template_name: template_name,
      template_id: template_response['id'],
      template_status: template_response['status']
    )
    template_response
  end

  def raise_create_template_error(response, template_name)
    error_message = template_response_error(response)
    log_template_error(
      'Create failed',
      action: 'create_template',
      template_name: template_name,
      error: error_message,
      error_payload: template_error_payload(response)
    )
    raise error_message
  end

  def recover_created_template(template_name, error)
    log_template_error('Create timed out', action: 'create_template', template_name: template_name, error: error.message)

    recovered_template = fetch_template_by_name(template_name)
    return log_recovered_template(template_name, recovered_template) if recovered_template.present?

    raise TemplateRequestTimeoutError, TEMPLATE_REQUEST_TIMEOUT_MESSAGE
  end

  def raise_delete_template_error(response, template_name)
    error_message = template_response_error(response)
    log_template_error(
      'Delete failed',
      action: 'delete_template',
      template_name: template_name,
      error: error_message,
      error_payload: template_error_payload(response)
    )
    raise error_message
  end

  def handle_delete_template_timeout(template_name, error)
    log_template_error('Delete timed out', action: 'delete_template', template_name: template_name, error: error.message)
    return true if fetch_template_by_name(template_name).blank?

    raise TemplateRequestTimeoutError, TEMPLATE_REQUEST_TIMEOUT_MESSAGE
  end

  def handle_template_fetch_failure(response, url, page)
    log_template_error(
      'Template fetch failed',
      action: 'fetch_templates',
      page: page,
      request_url: url,
      error: template_response_error(response),
      error_payload: template_error_payload(response)
    )
    []
  end

  def fetch_template_by_name(template_name)
    return if template_name.blank?

    response = HTTParty.get(
      "#{message_templates_path}?name=#{CGI.escape(template_name)}",
      headers: api_headers,
      timeout: TEMPLATE_RECOVERY_TIMEOUT
    )

    return unless response.success?

    parsed_template_response(response).fetch('data', []).find { |template| template['name'] == template_name }
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    log_template_error('Template recovery lookup timed out', action: 'fetch_template_by_name', template_name: template_name, error: e.message)
    nil
  end

  def log_recovered_template(template_name, recovered_template)
    log_template_info(
      'Create recovered after timeout',
      action: 'create_template',
      template_name: template_name,
      template_id: recovered_template['id'],
      template_status: recovered_template['status']
    )
    recovered_template
  end

  def template_name(payload)
    payload[:name] || payload['name']
  end

  def template_category(payload)
    payload[:category] || payload['category']
  end

  def template_response_error(response)
    parsed_response = response.parsed_response if response.respond_to?(:parsed_response)
    return parsed_response.dig('error', 'message') if parsed_response.respond_to?(:dig)

    parsed_response.presence || response.body
  end

  def template_error_payload(response)
    return unless response.respond_to?(:parsed_response)

    response.parsed_response.presence
  end

  def template_log_context(extra = {})
    {
      account_id: whatsapp_channel.account_id,
      inbox_id: whatsapp_channel.inbox&.id,
      channel_id: whatsapp_channel.id,
      provider: whatsapp_channel.provider
    }.merge(extra).compact
  end

  def log_template_info(message, extra = {})
    Rails.logger.info("[WHATSAPP TEMPLATES] #{message} #{template_log_context(extra).to_json}")
  end

  def log_template_error(message, extra = {})
    Rails.logger.error("[WHATSAPP TEMPLATES] #{message} #{template_log_context(extra).to_json}")
  end

  def reaction_error_message(response)
    return INVALID_REACTION_TARGET_MESSAGE if response.parsed_response&.dig('error', 'code') == INVALID_REACTION_TARGET_ERROR_CODE

    error_message(response).presence || 'Failed to send WhatsApp reaction'
  end

  def reaction_request_body(phone_number, message_id, emoji)
    {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: phone_number,
      type: 'reaction',
      reaction: {
        message_id: message_id,
        emoji: emoji
      }
    }
  end
end
# rubocop:enable Metrics/ModuleLength

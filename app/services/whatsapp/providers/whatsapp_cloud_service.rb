# rubocop:disable Metrics/ClassLength
class Whatsapp::Providers::WhatsappCloudService < Whatsapp::Providers::BaseService
  class TemplateRequestTimeoutError < RuntimeError; end

  TEMPLATE_REQUEST_TIMEOUT = 10
  TEMPLATE_RECOVERY_TIMEOUT = 3
  TEMPLATE_REQUEST_TIMEOUT_MESSAGE = 'WhatsApp API request timed out. Template state will sync shortly.'.freeze
  TEMPLATE_API_VERSION = 'v25.0'.freeze

  def send_message(phone_number, message)
    @message = message

    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif message.content_type == 'input_select'
      send_interactive_text_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_template(phone_number, template_info, message)
    template_body = template_body_parameters(template_info)

    request_body = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual', # Only individual messages supported (not group messages)
      to: phone_number,
      type: 'template',
      template: template_body
    }

    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: request_body.to_json
    )

    process_response(response, message)
  end

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

  def next_url(response)
    response['paging'] ? response['paging']['next'] : ''
  end

  def validate_provider_config?
    response = HTTParty.get(message_templates_path, headers: api_headers)
    return true if response.success?

    log_template_error(
      'Provider config validation failed',
      action: 'validate_provider_config',
      error: template_response_error(response),
      error_payload: template_error_payload(response)
    )
    false
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    log_template_error('Provider config validation timed out', action: 'validate_provider_config', error: e.message)
    raise
  end

  def api_headers
    { 'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}", 'Content-Type' => 'application/json' }
  end

  def create_csat_template(template_config)
    csat_template_service.create_template(template_config)
  end

  def delete_csat_template(template_name = nil)
    template_name ||= CsatTemplateNameService.csat_template_name(whatsapp_channel.inbox.id)
    csat_template_service.delete_template(template_name)
  end

  def get_template_status(template_name)
    csat_template_service.get_template_status(template_name)
  end

  def media_url(media_id)
    "#{api_base_path}/v13.0/#{media_id}"
  end

  private

  def csat_template_service
    @csat_template_service ||= Whatsapp::CsatTemplateService.new(whatsapp_channel)
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end

  # TODO: See if we can unify the API versions and for both paths and make it consistent with out facebook app API versions
  def phone_id_path
    "#{api_base_path}/v13.0/#{whatsapp_channel.provider_config['phone_number_id']}"
  end

  def business_account_path
    "#{api_base_path}/#{TEMPLATE_API_VERSION}/#{whatsapp_channel.provider_config['business_account_id']}"
  end

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

    parsed_response = response.parsed_response
    (parsed_response.presence)
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

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        context: whatsapp_reply_context(message),
        to: phone_number,
        text: { body: message.outgoing_content },
        type: 'text'
      }.to_json
    )

    process_response(response, message)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    type_content = {
      'link': attachment.download_url
    }
    type_content['caption'] = message.outgoing_content unless %w[audio sticker].include?(type)
    type_content['filename'] = attachment.file.filename if type == 'document'
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        :messaging_product => 'whatsapp',
        :context => whatsapp_reply_context(message),
        'to' => phone_number,
        'type' => type,
        type.to_s => type_content
      }.to_json
    )

    process_response(response, message)
  end

  def error_message(response)
    # https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes/#sample-response
    response.parsed_response&.dig('error', 'message')
  end

  def template_body_parameters(template_info)
    template_body = {
      name: template_info[:name],
      language: {
        policy: 'deterministic',
        code: template_info[:lang_code]
      }
    }

    # Enhanced template parameters structure
    # Note: Legacy format support (simple parameter arrays) has been removed
    # in favor of the enhanced component-based structure that supports
    # headers, buttons, and authentication templates.
    #
    # Expected payload format from frontend:
    # {
    #   processed_params: {
    #     body: { '1': 'John', '2': '123 Main St' },
    #     header: {
    #       media_url: 'https://...',
    #       media_type: 'image',
    #       media_name: 'filename.pdf' # Optional, for document templates only
    #     },
    #     buttons: [{ type: 'url', parameter: 'otp123456' }]
    #   }
    # }
    # This gets transformed into WhatsApp API component format:
    # [
    #   { type: 'body', parameters: [...] },
    #   { type: 'header', parameters: [...] },
    #   { type: 'button', sub_type: 'url', parameters: [...] }
    # ]
    template_body[:components] = template_info[:parameters] || []

    template_body
  end

  def whatsapp_reply_context(message)
    reply_to = message.content_attributes[:in_reply_to_external_id]
    return nil if reply_to.blank?

    {
      message_id: reply_to
    }
  end

  def send_interactive_text_message(phone_number, message)
    payload = create_payload_based_on_items(message)

    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        to: phone_number,
        interactive: payload,
        type: 'interactive'
      }.to_json
    )

    process_response(response, message)
  end
end
# rubocop:enable Metrics/ClassLength

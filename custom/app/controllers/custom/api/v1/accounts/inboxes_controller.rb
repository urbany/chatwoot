# Prepended into Api::V1::Accounts::InboxesController via the OSS file's
# existing `prepend_mod_with('Api::V1::Accounts::InboxesController')` call —
# no edits needed on the upstream file itself.
module Custom::Api::V1::Accounts::InboxesController
  private

  def format_csat_config(config)
    formatted = {
      'display_type' => config['display_type'] || 'emoji',
      'message' => config['message'] || '',
      'style' => config['style'] || 'default',
      :survey_rules => format_survey_rules(config),
      'button_text' => config['button_text'] || 'Please rate us',
      'language' => config['language'] || 'en',
      'cooldown' => config['cooldown'] || 0
    }
    format_template_config(config, formatted)
    formatted
  end

  def format_survey_rules(config)
    {
      'operator' => config.dig('survey_rules', 'operator') || 'contains',
      'values' => config.dig('survey_rules', 'values') || []
    }
  end

  def inbox_attributes
    [:name, :avatar, :greeting_enabled, :greeting_message, :enable_email_collect, :csat_survey_enabled,
     :enable_auto_assignment, :working_hours_enabled, :out_of_office_message, :timezone, :allow_messages_after_resolved,
     :lock_to_single_conversation, :portal_id, :sender_name_type, :business_name,
     { csat_config: [:display_type, :message, :style, :cooldown, :button_text, :language,
                     { survey_rules: [:operator, { values: [] }],
                       template: [:name, :template_id, :friendly_name, :content_sid, :approval_sid, :created_at, :language, :status] }] }]
  end
end

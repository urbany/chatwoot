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

  # `super` (not a full literal override) so this composes with
  # Enterprise::Api::V1::Accounts::InboxesController#inbox_attributes, which
  # appends `auto_assignment_config: [:max_assignment_limit]` via its own
  # `super + ee_inbox_attributes`. A full override here would sit closer in
  # the prepend chain than Enterprise's and silently swallow that addition.
  def inbox_attributes
    super.map do |attr|
      next attr unless attr.is_a?(Hash) && attr.key?(:csat_config)

      { csat_config: [:display_type, :message, :style, :cooldown, :button_text, :language,
                      { survey_rules: [:operator, { values: [] }],
                        template: [:name, :template_id, :friendly_name, :content_sid, :approval_sid, :created_at, :language, :status] }] }
    end
  end
end

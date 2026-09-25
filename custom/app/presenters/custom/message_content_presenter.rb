# Prepended into MessageContentPresenter via a one-time `prepend_mod_with`
# hook added to the OSS file (it had none upstream).
module Custom::MessageContentPresenter
  private

  def should_append_survey_link?
    super && !inline_style?
  end

  def inline_style?
    inbox.csat_config&.dig('style') == 'inline'
  end
end

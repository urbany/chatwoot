# Prepended into Message via the OSS file's existing
# `prepend_mod_with('Message')` call — no edits needed on the upstream file
# itself.
#
# Note: the `:reactions` store accessor stays as a small inline addition to
# the OSS `store :content_attributes, accessors: [...]` line — `store` is a
# class-body macro, not a plain method, so it isn't a good fit for prepend.
module Custom::Message
  private

  def execute_after_create_commit_callbacks
    super
    process_csat_rating
  end

  def process_csat_rating
    CsatSurveys::InlineProcessor.new(message: self).perform
  end
end

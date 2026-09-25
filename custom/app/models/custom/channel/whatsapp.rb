# Prepended into Channel::Whatsapp via a one-time `prepend_mod_with` hook
# added to the OSS file (it had none upstream).
#
# The OSS `delegate :send_message, ..., to: :provider_service` lines are left
# completely untouched (zero conflict risk) — these three delegated methods
# are added here instead of editing that macro call.
module Custom::Channel::Whatsapp
  def send_reaction(...)
    provider_service.send_reaction(...)
  end

  def create_template(...)
    provider_service.create_template(...)
  end

  def delete_template(...)
    provider_service.delete_template(...)
  end
end

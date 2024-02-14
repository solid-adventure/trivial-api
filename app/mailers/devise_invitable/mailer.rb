module DeviseInvitable
  module Mailer
    def invitation_instructions(record, token, opts = {})
      @token = token
      @trivial_ui_url = opts[:trivial_ui_url] || ENV['TRIVIAL_UI_URL']
      devise_mail(record, :invitation_instructions, opts)
    end
  end
end


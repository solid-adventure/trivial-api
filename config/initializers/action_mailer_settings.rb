# config/initializers/action_mailer_settings.rb

Rails.logger.info "BEGIN PRINT SMTP SETTINGS"
Rails.logger.info "Action Mailer SMTP Settings: #{ActionMailer::Base.smtp_settings}"
Rails.logger.info "END PRINT SMTP SETTINGS"

# frozen_string_literal: true

class SettingsMailer < ApplicationMailer
  def smtp_successful_setup(email)
    mail(to: email, from: email, subject: 'SMTP has been configured')
  end

  def smtp_test_email(to_email, from_email)
    @to_email = to_email
    mail(to: to_email, from: from_email, subject: I18n.t('docuseal_smtp_test_email'))
  end
end

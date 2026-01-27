# frozen_string_literal: true

class EmailSmtpSettingsTestController < ApplicationController
  authorize_resource :encrypted_config, only: %i[new create]

  def new
    @encrypted_config = EncryptedConfig.find_by(account: current_account, key: EncryptedConfig::EMAIL_SMTP_KEY)
  end

  def create
    @encrypted_config = EncryptedConfig.find_by(account: current_account, key: EncryptedConfig::EMAIL_SMTP_KEY)

    if @encrypted_config&.value.blank?
      return redirect_to settings_email_index_path, alert: I18n.t('please_configure_smtp_settings_first')
    end

    email = params[:email].to_s.strip

    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      return redirect_to settings_email_index_path, alert: I18n.t('please_enter_a_valid_email_address')
    end

    # Force SMTP delivery to actually test the connection (bypass letter_opener in development)
    smtp_settings = build_smtp_settings(@encrypted_config)
    from_email = @encrypted_config.value['from_email'] || current_user.email

    mail = SettingsMailer.smtp_test_email(email, from_email)
    mail.delivery_method(:smtp, smtp_settings)
    mail.deliver_now!

    redirect_to settings_email_index_path, notice: I18n.t('test_email_has_been_sent_to', email:)
  rescue StandardError => e
    redirect_to settings_email_index_path, alert: I18n.t('failed_to_send_test_email', error: e.message)
  end

  private

  def build_smtp_settings(encrypted_config)
    value = encrypted_config.value

    {
      user_name: value['username'],
      password: value['password'],
      address: value['host'],
      port: value['port'],
      domain: value['domain'],
      openssl_verify_mode: value['security'] == 'noverify' ? OpenSSL::SSL::VERIFY_NONE : nil,
      authentication: value['password'].present? ? value.fetch('authentication', 'plain') : nil,
      enable_starttls_auto: value['security'] != 'tls',
      open_timeout: 15,
      read_timeout: 25,
      ssl: value['security'] == 'ssl',
      tls: value['security'] == 'tls' || (value['security'].blank? && value['port'].to_s == '465')
    }.compact_blank
  end
end

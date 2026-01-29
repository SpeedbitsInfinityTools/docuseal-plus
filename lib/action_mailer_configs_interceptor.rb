# frozen_string_literal: true

module ActionMailerConfigsInterceptor
  OPEN_TIMEOUT = ENV.fetch('SMTP_OPEN_TIMEOUT', '15').to_i
  READ_TIMEOUT = ENV.fetch('SMTP_READ_TIMEOUT', '25').to_i

  module_function

  def delivering_email(message)
    if Docuseal.demo?
      message.delivery_method(:test)

      return message
    end

    # In production with ENV-based SMTP config
    if Rails.env.production? && Rails.application.config.action_mailer.delivery_method
      from = ENV.fetch('SMTP_FROM', '').to_s.split(',').sample

      if from.present?
        if from.match?(User::FULL_EMAIL_REGEXP)
          message[:from] = message[:from].to_s.sub(User::EMAIL_REGEXP, from)
        else
          message.from = from
        end
      end

      return message
    end

    # Use database SMTP settings if configured (works in both development and production)
    unless Docuseal.multitenant?
      email_configs = EncryptedConfig.order(:account_id).find_by(key: EncryptedConfig::EMAIL_SMTP_KEY)

      if email_configs&.value.present?
        message.delivery_method(:smtp, build_smtp_configs_hash(email_configs))

        message.from = %("#{email_configs.account.name.to_s.delete('"')}" <#{email_configs.value['from_email']}>)
      elsif Rails.env.production?
        # Only fall back to test in production if no SMTP configured
        message.delivery_method(:test)
      end
      # In development without SMTP config, let it use letter_opener_web (default)
    end

    message
  end

  def build_smtp_configs_hash(email_configs)
    value = email_configs.value

    {
      user_name: value['username'],
      password: value['password'],
      address: value['host'],
      port: value['port'],
      domain: value['domain'],
      openssl_verify_mode: value['security'] == 'noverify' ? OpenSSL::SSL::VERIFY_NONE : nil,
      authentication: value['password'].present? ? value.fetch('authentication', 'plain') : nil,
      enable_starttls_auto: value['security'] != 'tls',
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT,
      ssl: value['security'] == 'ssl',
      tls: value['security'] == 'tls' || (value['security'].blank? && value['port'].to_s == '465')
    }.compact_blank
  end
end

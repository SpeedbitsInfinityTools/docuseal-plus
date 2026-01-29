# frozen_string_literal: true

class NotificationsSettingsTestController < ApplicationController
  authorize_resource :account_config, only: %i[new create]

  def new
    @account_config = AccountConfig.find_or_initialize_by(
      account: current_account,
      key: AccountConfig::SUBMITTER_REMINDERS
    )
  end

  def create
    email = params[:email].to_s.strip

    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      return redirect_to settings_notifications_path, alert: I18n.t('please_enter_a_valid_email_address')
    end

    # Find any template to use as base
    template = current_account.templates.where(archived_at: nil).first

    return redirect_to settings_notifications_path, alert: I18n.t('no_templates_found_for_testing') if template.nil?

    # Create a temporary test submission and submitter
    submission, submitter = create_test_submission(template, email)

    begin
      # Send the reminder email
      mail = SubmitterMailer.invitation_email(submitter)

      # Add reminder prefix to subject if configured
      reminder_config = current_account.account_configs.find_by(key: AccountConfig::SUBMITTER_REMINDERS)
      subject_prefix = reminder_config&.value&.dig('subject_prefix')
      mail.subject = "#{subject_prefix}#{mail.subject}" if subject_prefix.present?

      # Force SMTP delivery to actually send the email (bypass letter_opener in development)
      smtp_config = EncryptedConfig.find_by(account: current_account, key: EncryptedConfig::EMAIL_SMTP_KEY)
      mail.delivery_method(:smtp, build_smtp_settings(smtp_config)) if smtp_config&.value.present?

      mail.deliver_now!

      redirect_to settings_notifications_path, notice: I18n.t('test_reminder_email_has_been_sent_to', email:)
    ensure
      # Always clean up the test submission
      submission&.destroy
    end
  rescue StandardError => e
    redirect_to settings_notifications_path, alert: I18n.t('failed_to_send_test_reminder', error: e.message)
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

  def create_test_submission(template, email)
    # Create a temporary submission
    submission = current_account.submissions.create!(
      template:,
      created_by_user: current_user,
      source: 'invite',
      template_fields: template.fields,
      template_schema: template.schema,
      template_submitters: template.submitters,
      name: '[Test Reminder] - will be deleted'
    )

    # Get the first submitter UUID from the template
    submitter_uuid = template.submitters&.first&.dig('uuid') || SecureRandom.uuid

    # Create a temporary submitter
    submitter = submission.submitters.create!(
      account: current_account,
      uuid: submitter_uuid,
      email:,
      name: 'Test Recipient',
      sent_at: Time.current # Mark as sent so it looks like a real pending submitter
    )

    [submission, submitter]
  end
end

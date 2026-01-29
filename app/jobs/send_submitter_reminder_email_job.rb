# frozen_string_literal: true

class SendSubmitterReminderEmailJob
  include Sidekiq::Job

  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])
    reminder_number = params['reminder_number'] || 1

    return if submitter.completed_at?
    return if submitter.declined_at?
    return if submitter.submission.archived_at?
    return if submitter.template&.archived_at?

    unless Accounts.can_send_invitation_emails?(submitter.account)
      Rollbar.warning("Skip reminder email: #{submitter.account.id}") if defined?(Rollbar)

      return
    end

    mail = SubmitterMailer.invitation_email(submitter)

    # Add reminder prefix to subject if configured
    reminder_config = submitter.account.account_configs.find_by(key: AccountConfig::SUBMITTER_REMINDERS)
    subject_prefix = reminder_config&.value&.dig('subject_prefix')
    mail.subject = "#{subject_prefix}#{mail.subject}" if subject_prefix.present?

    Submitters::ValidateSending.call(submitter, mail)

    mail.deliver_now!

    SubmissionEvent.create!(
      submitter:,
      event_type: 'send_reminder_email',
      data: { reminder_number: }
    )
  end
end

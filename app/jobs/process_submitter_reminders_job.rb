# frozen_string_literal: true

class ProcessSubmitterRemindersJob
  include Sidekiq::Job

  # In development: run every minute to support short testing intervals
  # In production: run every hour for efficiency
  def self.schedule_interval
    Rails.env.production? ? 1.hour : 1.minute
  end

  DURATION_MAP = {
    'two_minutes' => 2.minutes,
    'one_hour' => 1.hour,
    'two_hours' => 2.hours,
    'four_hours' => 4.hours,
    'eight_hours' => 8.hours,
    'twelve_hours' => 12.hours,
    'twenty_four_hours' => 24.hours,
    'two_days' => 2.days,
    'three_days' => 3.days,
    'four_days' => 4.days,
    'five_days' => 5.days,
    'six_days' => 6.days,
    'seven_days' => 7.days,
    'eight_days' => 8.days,
    'fifteen_days' => 15.days,
    'twenty_one_days' => 21.days,
    'thirty_days' => 30.days
  }.freeze

  def perform
    Account.active.find_each do |account|
      process_account_reminders(account)
    rescue StandardError => e
      # Log error but continue processing other accounts
      Rails.logger.error("ProcessSubmitterRemindersJob failed for account #{account.id}: #{e.message}")
      Rollbar.error(e, account_id: account.id) if defined?(Rollbar)
    end
  ensure
    # Always reschedule to keep the reminder system running
    self.class.perform_in(self.class.schedule_interval)
  end

  private

  def process_account_reminders(account)
    reminder_config = account.account_configs.find_by(key: AccountConfig::SUBMITTER_REMINDERS)
    return if reminder_config&.value.blank?

    durations = extract_durations(reminder_config.value)
    return if durations.empty?

    pending_submitters(account).find_each do |submitter|
      check_and_send_reminder(submitter, durations)
    end
  end

  def extract_durations(config_value)
    durations = []

    %w[first_duration second_duration third_duration].each_with_index do |key, index|
      duration_key = config_value[key]
      next if duration_key.blank?

      duration = DURATION_MAP[duration_key]
      durations << { number: index + 1, duration: } if duration
    end

    durations
  end

  def pending_submitters(account)
    account.submitters
           .joins(submission: :template)
           .where(completed_at: nil, declined_at: nil)
           .where(submissions: { archived_at: nil })
           .where(templates: { archived_at: nil })
           .where.not(email: nil)
           .where.not(sent_at: nil)
  end

  def check_and_send_reminder(submitter, durations)
    sent_reminders = submitter.submission.submission_events
                              .where(submitter:, event_type: 'send_reminder_email')
                              .pluck(:data)
                              .filter_map { |d| d['reminder_number'] }

    durations.each do |duration_info|
      reminder_number = duration_info[:number]
      duration = duration_info[:duration]

      next if sent_reminders.include?(reminder_number)

      # Check if it's time to send this reminder
      reminder_time = submitter.sent_at + duration
      next unless Time.current >= reminder_time

      # Check if previous reminders were sent (if applicable)
      if reminder_number > 1
        previous_sent = sent_reminders.include?(reminder_number - 1)
        next unless previous_sent
      end

      SendSubmitterReminderEmailJob.perform_async(
        'submitter_id' => submitter.id,
        'reminder_number' => reminder_number
      )

      # Only send one reminder at a time
      break
    end
  end
end

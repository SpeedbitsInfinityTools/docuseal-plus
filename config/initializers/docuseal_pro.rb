# frozen_string_literal: true

# DocuSeal Pro Features Initializer
# This file loads and activates pro features for the self-hosted version.

Rails.application.config.to_prepare do
  # Feature 1: Account Logo
  require_dependency 'docuseal_pro/account_logo'
  Account.include(DocusealPro::AccountLogo) unless Account.include?(DocusealPro::AccountLogo)

  # Feature 2: Override stamp attachment to use account logo
  require_dependency 'docuseal_pro/create_stamp_attachment_override'
  Submitters::CreateStampAttachment.prepend(DocusealPro::CreateStampAttachmentOverride)

  # Feature 3: Override audit trail to use account logo
  require_dependency 'docuseal_pro/generate_audit_trail_override'
  Submissions::GenerateAuditTrail.prepend(DocusealPro::GenerateAuditTrailOverride)
end

# Feature 4: Schedule the reminder job
# Use ActiveSupport load hook to schedule when Sidekiq actually starts (works with embedded Sidekiq in Puma)
ActiveSupport.on_load(:sidekiq_config) do |_config|
  # Check if the job is already scheduled to avoid duplicates on restart
  unless Sidekiq::ScheduledSet.new.any? { |job| job.klass == 'ProcessSubmitterRemindersJob' }
    Rails.logger.info('ProcessSubmitterRemindersJob: Scheduling initial reminder job')
    ProcessSubmitterRemindersJob.perform_in(1.minute)
  else
    Rails.logger.info('ProcessSubmitterRemindersJob: Job already scheduled, skipping')
  end
end

# frozen_string_literal: true

# DocuSeal Plus Configuration
# This module centralizes all Plus feature flags and configurations
# Making it easy to enable/disable features and track what's modified

module DocusealPlus
  class << self
    # Feature flags - set to false to disable specific Plus features
    def config
      @config ||= {
        # Plus Features
        user_roles_enabled: true,
        company_logo_enabled: true,
        email_reminders_enabled: true,

        # UI Modifications
        hide_upgrade_button: true,
        hide_plans_menu: true,
        hide_sms_menu: true,
        hide_console_menu: true,
        hide_sso_menu: true,
        hide_trusted_signature_promo: true,
        show_speedbits_banner: true,

        # Branding
        fork_name: 'DocuSeal Plus',
        fork_company: 'Speedbits',
        fork_company_full: 'Smart In Venture GmbH',
        fork_website: 'https://www.speedbits.io',
        fork_repository: 'https://github.com/smartinventure/docuseal'
      }
    end

    def enabled?(feature)
      config[feature] == true
    end

    def setting(key)
      config[key]
    end

    # Helper methods for views
    def hide_upgrade_button?
      enabled?(:hide_upgrade_button)
    end

    def hide_plans_menu?
      enabled?(:hide_plans_menu)
    end

    def hide_sms_menu?
      enabled?(:hide_sms_menu)
    end

    def hide_console_menu?
      enabled?(:hide_console_menu)
    end

    def hide_sso_menu?
      enabled?(:hide_sso_menu)
    end

    def hide_trusted_signature_promo?
      enabled?(:hide_trusted_signature_promo)
    end

    def show_speedbits_banner?
      enabled?(:show_speedbits_banner)
    end
  end
end

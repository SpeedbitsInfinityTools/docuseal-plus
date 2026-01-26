# DocuSeal Plus - Change Tracking

This document tracks all modifications made to the original DocuSeal codebase for the Plus version.
Use this when updating from upstream to identify files that need attention during merges.

## Configuration

All Plus features and UI modifications can be toggled via:

**`lib/docuseal_plus.rb`** - Central configuration module

```ruby
DocusealPlus.config
# Returns hash with all feature flags and settings

DocusealPlus.enabled?(:feature_name)
# Check if a feature is enabled

DocusealPlus.setting(:setting_name)
# Get a setting value
```

## New Files (Plus-specific)

These files are new and won't conflict with upstream updates:

| File | Purpose |
|------|---------|
| `lib/docuseal_plus.rb` | Central configuration module |
| `lib/docuseal_pro/account_logo.rb` | Account logo attachment concern |
| `lib/docuseal_pro/create_stamp_attachment_override.rb` | Override for stamp with logo |
| `lib/docuseal_pro/generate_audit_trail_override.rb` | Override for audit trail with logo |
| `config/initializers/docuseal_pro.rb` | Loads Pro modules |
| `app/views/shared/_speedbits_banner.html.erb` | Disclaimer banner partial |
| `app/controllers/account_logo_controller.rb` | Logo upload controller |
| `app/jobs/process_submitter_reminders_job.rb` | Email reminder job |
| `app/jobs/send_submitter_reminder_email_job.rb` | Send reminder email job |
| `.devcontainer/` | Dev container configuration |

## Modified Files

### Views (UI Changes)

| File | Changes | Merge Strategy |
|------|---------|----------------|
| `app/views/shared/_navbar_buttons.html.erb` | Added `DocusealPlus.hide_upgrade_button?` conditional | Look for `DocusealPlus` conditions |
| `app/views/shared/_settings_nav.html.erb` | Added `DocusealPlus.hide_*_menu?` conditionals for SMS, Plans, Console, SSO | Look for `DocusealPlus` conditions |
| `app/views/shared/_navbar_warning.html.erb` | Added Speedbits banner render with `DocusealPlus.show_speedbits_banner?` | Small change, easy to re-apply |
| `app/views/personalization_settings/_logo_form.html.erb` | Fixed form to use `scope: :account`, fixed button HTML | Compare and merge carefully |
| `app/views/users/_role_select.html.erb` | Enabled role selection | Check if upstream changes |
| `app/views/errors/404.html` | Updated styling to match dark theme | Can be overwritten |
| `app/views/errors/422.html` | Updated styling to match dark theme | Can be overwritten |
| `app/views/errors/500.html` | Updated styling to match dark theme | Can be overwritten |

### Models

| File | Changes | Merge Strategy |
|------|---------|----------------|
| `app/models/user.rb` | Added `EDITOR_ROLE`, `VIEWER_ROLE`, `SELECTABLE_ROLES`, role methods, `cannot_remove_last_admin` validation | Merge additions carefully |
| `app/models/account.rb` | Logo attachment via `DocusealPro::AccountLogo` concern (loaded in initializer) | No direct changes |

### Controllers

| File | Changes | Merge Strategy |
|------|---------|----------------|
| `app/controllers/users_controller.rb` | Added last admin protection in `destroy` action | Merge additions |

### Lib

| File | Changes | Merge Strategy |
|------|---------|----------------|
| `lib/ability.rb` | Added `editor_abilities`, `viewer_abilities`, `integration_abilities` | Merge additions |

### Other

| File | Changes |
|------|---------|
| `README.md` | Complete rewrite for fork |

## Update Procedure

When updating from upstream DocuSeal:

1. **Backup your changes:**
   ```bash
   git stash
   # or create a branch
   git checkout -b backup-plus-changes
   ```

2. **Fetch upstream:**
   ```bash
   git remote add upstream https://github.com/docusealco/docuseal.git
   git fetch upstream
   ```

3. **Merge upstream:**
   ```bash
   git checkout main
   git merge upstream/master
   ```

4. **Resolve conflicts:**
   - For files with `DocusealPlus` conditions: ensure conditions are preserved
   - For new Plus files: keep them (no conflicts expected)
   - For error pages: can overwrite with Plus versions

5. **Test thoroughly:**
   - User role functionality
   - Logo upload
   - Email reminders
   - UI modifications (menu items hidden)
   - Speedbits banner

## Feature Flags

To disable a Plus feature, edit `lib/docuseal_plus.rb`:

```ruby
# To show the original upgrade button:
hide_upgrade_button: false

# To show original menu items:
hide_plans_menu: false
hide_sms_menu: false
hide_console_menu: false
hide_sso_menu: false

# To hide the Speedbits banner:
show_speedbits_banner: false
```

## Contact

For issues with Plus features:
- Repository: https://github.com/smartinventure/docuseal
- Company: Speedbits / Smart In Venture GmbH
- Website: https://www.speedbits.io

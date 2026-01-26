# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # All users can manage their own configs
    can :manage, EncryptedUserConfig, user_id: user.id
    can :manage, UserConfig, user_id: user.id

    case user.role
    when User::ADMIN_ROLE
      admin_abilities(user)
    when User::EDITOR_ROLE
      editor_abilities(user)
    when User::VIEWER_ROLE
      viewer_abilities(user)
    when User::INTEGRATION_ROLE
      integration_abilities(user)
    else # rubocop:disable Lint/DuplicateBranch
      # Intentionally defaults to viewer_abilities for unknown roles (same as VIEWER_ROLE)
      viewer_abilities(user)
    end
  end

  private

  def admin_abilities(user)
    # Admins have full access
    can %i[read create update], Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'manage')
    end

    can :destroy, Template, account_id: user.account_id
    can :manage, TemplateFolder, account_id: user.account_id
    can :manage, TemplateSharing, template: { account_id: user.account_id }
    can :manage, Submission, account_id: user.account_id
    can :manage, Submitter, account_id: user.account_id
    can :manage, User, account_id: user.account_id
    can :manage, EncryptedConfig, account_id: user.account_id
    can :manage, AccountConfig, account_id: user.account_id
    can :manage, Account, id: user.account_id
    can :manage, AccessToken, user_id: user.id
    can :manage, WebhookUrl, account_id: user.account_id
  end

  def editor_abilities(user)
    # Editors can manage templates and submissions, but not users, account settings, or webhooks
    can %i[read create update], Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'manage')
    end

    can :destroy, Template, account_id: user.account_id
    can :manage, TemplateFolder, account_id: user.account_id
    can :manage, TemplateSharing, template: { account_id: user.account_id }
    can :manage, Submission, account_id: user.account_id
    can :manage, Submitter, account_id: user.account_id

    # Editors can only read account info, not modify
    can :read, Account, id: user.account_id

    # Editors can manage their own access token
    can :manage, AccessToken, user_id: user.id

    # Editors cannot manage: User, EncryptedConfig, AccountConfig, WebhookUrl
  end

  def viewer_abilities(user)
    # Viewers have read-only access
    can :read, Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'read')
    end

    can :read, TemplateFolder, account_id: user.account_id
    can :read, Submission, account_id: user.account_id
    can :read, Submitter, account_id: user.account_id
    can :read, Account, id: user.account_id

    # Viewers cannot manage: User, EncryptedConfig, AccountConfig, AccessToken, WebhookUrl
  end

  def integration_abilities(user)
    # Integration users (API) have similar access to editors for templates/submissions
    can %i[read create update], Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'manage')
    end

    can :destroy, Template, account_id: user.account_id
    can :manage, TemplateFolder, account_id: user.account_id
    can :manage, TemplateSharing, template: { account_id: user.account_id }
    can :manage, Submission, account_id: user.account_id
    can :manage, Submitter, account_id: user.account_id
    can :read, Account, id: user.account_id
    can :manage, AccessToken, user_id: user.id
  end
end

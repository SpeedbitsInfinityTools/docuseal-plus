# frozen_string_literal: true

class AccountLogoController < ApplicationController
  before_action :load_account
  authorize_resource :account

  def create
    if logo_params[:logo].present?
      current_account.logo.attach(logo_params[:logo])

      if current_account.valid?
        redirect_back(fallback_location: settings_personalization_path,
                      notice: I18n.t('settings_have_been_saved'))
      else
        redirect_back(fallback_location: settings_personalization_path,
                      alert: current_account.errors.full_messages.join(', '))
      end
    else
      redirect_back(fallback_location: settings_personalization_path, alert: 'Please select a file to upload')
    end
  end

  def destroy
    current_account.logo.purge if current_account.logo.attached?

    redirect_back(fallback_location: settings_personalization_path, notice: I18n.t('settings_have_been_saved'))
  end

  private

  def load_account
    @account = current_account
  end

  def logo_params
    params.require(:account).permit(:logo)
  end
end

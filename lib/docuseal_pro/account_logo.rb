# frozen_string_literal: true

module DocusealPro
  module AccountLogo
    extend ActiveSupport::Concern

    ALLOWED_LOGO_TYPES = %w[image/png image/jpeg image/jpg image/gif image/webp].freeze
    MAX_LOGO_SIZE = 5.megabytes

    included do
      has_one_attached :logo

      validate :validate_logo_type_and_size
    end

    def logo_url
      return nil unless logo.attached?

      Rails.application.routes.url_helpers.rails_blob_url(logo, **Docuseal.default_url_options)
    end

    private

    def validate_logo_type_and_size
      return unless logo.attached?
      return unless logo.blob.present?

      unless logo.blob.content_type.in?(ALLOWED_LOGO_TYPES)
        errors.add(:logo, 'must be a PNG, JPEG, GIF, or WebP image')
        logo.purge
      end

      if logo.blob.byte_size > MAX_LOGO_SIZE
        errors.add(:logo, 'must be less than 5MB')
        logo.purge
      end
    end
  end
end

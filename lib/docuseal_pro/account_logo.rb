# frozen_string_literal: true

module DocusealPro
  module AccountLogo
    extend ActiveSupport::Concern

    ALLOWED_LOGO_TYPES = %w[image/png image/jpeg image/jpg image/gif image/webp].freeze
    MAX_LOGO_SIZE = 5.megabytes
    MAX_LOGO_DIMENSION = 1024 # Max width or height in pixels

    included do
      has_one_attached :logo

      validate :validate_logo_type_and_size
      after_save :resize_logo_if_needed, if: -> { logo.attached? }
    end

    def logo_url
      return nil unless logo.attached?

      Rails.application.routes.url_helpers.rails_blob_url(logo, **Docuseal.default_url_options)
    end

    # Get a resized variant for display (optional, for on-the-fly resizing)
    def logo_variant(size: 400)
      return nil unless logo.attached?

      logo.variant(resize_to_limit: [size, size])
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

    # Resize the logo if it exceeds MAX_LOGO_DIMENSION
    def resize_logo_if_needed
      return unless logo.attached?
      return unless logo.blob.present?
      return unless logo.blob.image?

      # Analyze the blob to get dimensions (if not already analyzed)
      logo.blob.analyze unless logo.blob.analyzed?

      metadata = logo.blob.metadata
      width = metadata['width'].to_i
      height = metadata['height'].to_i

      return if width.zero? || height.zero?
      return if width <= MAX_LOGO_DIMENSION && height <= MAX_LOGO_DIMENSION

      # Resize the image
      resize_logo(width, height)
    rescue StandardError => e
      Rails.logger.warn "Could not check logo dimensions: #{e.message}"
    end

    def resize_logo(original_width, original_height)
      # Calculate new dimensions maintaining aspect ratio
      if original_width > original_height
        new_width = MAX_LOGO_DIMENSION
        new_height = (original_height.to_f / original_width * MAX_LOGO_DIMENSION).round
      else
        new_height = MAX_LOGO_DIMENSION
        new_width = (original_width.to_f / original_height * MAX_LOGO_DIMENSION).round
      end

      # Process and replace the image
      processed = logo.blob.open do |file|
        ImageProcessing::Vips
          .source(file)
          .resize_to_limit(new_width, new_height)
          .convert(logo.blob.content_type.split('/').last) # Keep original format
          .call
      end

      # Attach the resized image, replacing the original
      logo.attach(
        io: processed,
        filename: logo.blob.filename.to_s,
        content_type: logo.blob.content_type
      )

      Rails.logger.info "Logo resized from #{original_width}x#{original_height} to #{new_width}x#{new_height}"
    rescue StandardError => e
      Rails.logger.error "Failed to resize logo: #{e.message}"
      # Don't fail the save if resizing fails - keep the original
    end
  end
end

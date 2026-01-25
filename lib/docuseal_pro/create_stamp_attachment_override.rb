# frozen_string_literal: true

module DocusealPro
  module CreateStampAttachmentOverride
    def load_logo(submitter)
      account = submitter.submission.account

      if account.logo.attached?
        StringIO.new(account.logo.download)
      else
        PdfIcons.stamp_logo_io
      end
    end
  end
end

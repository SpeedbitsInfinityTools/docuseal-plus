# frozen_string_literal: true

module DocusealPro
  module GenerateAuditTrailOverride
    def add_logo(column, submission = nil)
      account = submission&.account

      if account&.logo&.attached?
        logo_io = StringIO.new(account.logo.download)
        column.image(logo_io, width: 40, height: 40, position: :float)

        column.formatted_text([{ text: account.name }],
                              font_size: 20,
                              font: [FONT_NAME, { variant: :bold }],
                              width: 200,
                              padding: [5, 0, 0, 8],
                              position: :float, text_align: :left)
      else
        super
      end
    end
  end
end

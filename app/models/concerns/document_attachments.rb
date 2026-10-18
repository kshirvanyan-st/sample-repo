# Uploaded documents and photos (licenses, IDs, car papers). Each model lists its DOCUMENTS;
# this adds the attachments and checks their type and size. Files are served only through
# DocumentsController, never by public Active Storage URLs.
module DocumentAttachments
  extend ActiveSupport::Concern

  CONTENT_TYPES = %w[ image/jpeg image/png image/webp image/heic image/heif application/pdf ].freeze
  MAX_SIZE = 10.megabytes

  included do
    self::DOCUMENTS.each { |name| has_one_attached name }
    validate :documents_are_acceptable
  end

  def missing_documents
    self.class::DOCUMENTS.reject { |name| public_send(name).attached? }
  end

  private
    def documents_are_acceptable
      self.class::DOCUMENTS.each do |name|
        next unless (change = attachment_changes[name.to_s]).respond_to?(:blob)

        errors.add(name, :document_type) unless sniffed_type(change.attachable, change.blob).in?(CONTENT_TYPES)
        errors.add(name, :document_size, max: MAX_SIZE / 1.megabyte) if change.blob.byte_size > MAX_SIZE
      end
    end

    # The type from the file's own bytes, ignoring its name and the type the browser declared.
    def sniffed_type(attachable, blob)
      io = attachable.try(:tempfile) || (attachable[:io] if attachable.is_a?(Hash))
      return blob.content_type unless io

      Marcel::MimeType.for(io).tap { io.rewind }
    end

    def documents_attached
      missing_documents.each { |name| errors.add(name, :blank) }
    end
end

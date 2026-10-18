# Streams an uploaded driver document to its owner or to an admin. Documents never get public
# Active Storage URLs, which anyone holding the link could open.
class DocumentsController < ApplicationController
  def show
    attachment = ActiveStorage::Attachment.find(params[:id])
    owner = owner_of(attachment.record)
    raise ActiveRecord::RecordNotFound unless owner && (owner == Current.user || Current.user.admin?)

    response.headers["Cache-Control"] = "private, no-store"
    send_data attachment.download, type: attachment.content_type, disposition: :inline, filename: attachment.filename.to_s
  end

  private
    def owner_of(record)
      case record
      when DriverProfile then record.user
      when Vehicle then record.driver_profile.user
      end
    end
end

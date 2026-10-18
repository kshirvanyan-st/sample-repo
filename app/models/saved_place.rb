class SavedPlace < ApplicationRecord
  belongs_to :user

  enum :kind, { home: 0, work: 1, other: 2 }, validate: true

  validates :address, presence: true, length: { maximum: 200 }
  validates :label, length: { maximum: 40 }
  validates :kind, uniqueness: { scope: :user_id }, unless: :other?

  scope :ordered, -> { order(:kind, :created_at) }

  def title
    other? ? label.presence || address : I18n.t("saved_places.kinds.#{kind}")
  end
end

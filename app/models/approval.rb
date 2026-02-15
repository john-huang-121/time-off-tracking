class Approval < ApplicationRecord
  # Enums
  enum :decision, { approved: 1, denied: 2, cancelled: 3 }, prefix: true

  # Associations
  belongs_to :time_off_request, inverse_of: :approvals
  belongs_to :reviewer, class_name: "User"

  # Validations
  validates :decision, presence: true

  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :recent, -> { ordered.limit(10) }

  # Instance methods
  def decision_description
    decision.humanize
  end

  def performed_by
    reviewer.full_name.presence || reviewer.email
  end
end
class Approval < ApplicationRecord
  enum :decision, { approved: 0, denied: 1, canceled: 2 }, prefix: true

  belongs_to :time_off_request, inverse_of: :approvals
  belongs_to :reviewer, class_name: "User"

  validates :decision, presence: true

  scope :ordered, -> { order(created_at: :desc) }
  scope :recent, -> { ordered.limit(10) }

  alias_attribute :reviewed_at, :updated_at
  alias_attribute :review_notes, :comment

  # Instance methods
  def decision_description
    decision.humanize
  end

  def performed_by
    reviewer.full_name.presence || reviewer.email
  end
end

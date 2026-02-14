class Approval < ApplicationRecord
  # Enums
  enum :action, { approved: 1, denied: 2, cancelled: 3 }

  # Associations
  belongs_to :time_off_request
  belongs_to :user

  # Validations
  validates :action, presence: true

  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :recent, -> { order(created_at: :desc).limit(10) }

  # Instance methods
  def action_description
    case action
    when 'approved'
      'Approved'
    when 'denied'
      'Denied'
    when 'cancelled'
      'Cancelled'
    end
  end

  def performed_by
    user.full_name
  end
end
class TimeOffRequest < ApplicationRecord
  belongs_to :user
  has_many :approvals, dependent: :destroy, inverse_of: :time_off_request
  has_one :latest_approval, -> { order(created_at: :desc) }, class_name: "Approval", inverse_of: :time_off_request

  enum :time_off_type, { vacation: 0, sick: 1, personal: 2 }, prefix: true
  enum :status, { pending: 0, approved: 1, denied: 2, canceled: 3 }, prefix: true

  scope :ordered, -> { order(created_at: :desc) }
  scope :current_year, -> { where(start_date: Date.current.beginning_of_year..Date.current.end_of_year) }
  scope :upcoming, -> { where("start_date >= ?", Date.current) }
  scope :for_approval_by, ->(user) do
    base = where(status: statuses[:pending]) # or `status_pending` if you prefer

    if user.role_admin?
      base
    elsif user.role_manager?
      base.joins(user: :profile).where(profiles: { manager_id: user.id })
    else
      none
    end
  end

  validates :start_date, :end_date, :time_off_type, :status, presence: true
  validate :end_date_on_or_after_start_date

  delegate :reviewed_at, :review_notes, to: :latest_approval, prefix: true, allow_nil: true

  after_create_commit -> { TimeOffRequestMailer.request_created(id).deliver_later }
  after_update_commit :notify_status_change, if: -> { saved_change_to_status? }

  def reviewed_by
    latest_approval&.reviewer
  end

  def total_days
    return 0 if start_date.blank? || end_date.blank?
    (end_date - start_date).to_i + 1
  end

  def approve!(reviewer:, comment: nil)
    transition!(reviewer: reviewer, decision: :approved, comment: comment)
  end

  def deny!(reviewer:, comment: nil)
    transition!(reviewer: reviewer, decision: :denied, comment: comment)
  end

  def cancel!(reviewer:, comment: nil)
    transition!(reviewer: reviewer, decision: :canceled, comment: comment)
  end

  def can_be_canceled?
    status_pending? || status_approved?
  end

  private

  def notify_status_change
    prev_status, new_status = saved_change_to_status
    NotifyTimeOffRequestStatusChangeJob.perform_later(id, prev_status, new_status)
  end

  def transition!(reviewer:, decision:, comment:)
    transaction do
      approvals.create!(reviewer: reviewer, decision: decision, comment: comment) if reviewer.present?
      update!(status: decision)
    end

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
    false
  end

  def end_date_on_or_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "must be on or after the start date")
  end
end

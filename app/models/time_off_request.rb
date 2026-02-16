class TimeOffRequest < ApplicationRecord
  belongs_to :user
  has_many :approvals, dependent: :destroy, inverse_of: :time_off_request
  has_one :latest_approval, -> { order(created_at: :desc) }, class_name: "Approval", inverse_of: :time_off_request

  enum :time_off_type, { vacation: 0, sick: 1, personal: 2 }, prefix: true
  enum :status, { pending: 0, approved: 1, denied: 2, canceled: 3 }, prefix: true

  scope :ordered, -> { order(created_at: :desc) }
  scope :current_year, -> { where(start_date: Date.current.beginning_of_year..Date.current.end_of_year) }
  scope :upcoming, -> { where("start_date >= ?", Date.current) }

  validates :start_date, :end_date, :time_off_type, :status, presence: true
  validate :end_date_on_or_after_start_date

  after_create_commit -> { TimeOffRequestMailer.request_created(id).deliver_later }

  def reviewed_by
    latest_approval&.reviewer
  end

  def total_days
    return 0 if start_date.blank? || end_date.blank?
    (end_date - start_date).to_i + 1
  end

  private

  def end_date_on_or_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "must be on or after the start date")
  end
end

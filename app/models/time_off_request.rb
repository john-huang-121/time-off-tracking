class TimeOffRequest < ApplicationRecord
  belongs_to :user

  enum :time_off_type, { vacation: 0, sick: 1, personal: 2 }, prefix: true
  enum :status, { pending: 0, approved: 1, denied: 2, canceled: 3 }, prefix: true

  scope :ordered, -> { order(created_at: :desc) }
  scope :current_year, -> { where(start_date: Time.current.beginning_of_year..Time.current.end_of_year) }
  scope :upcoming, -> { where("start_date >= ?", Date.current) }

  validates :start_date, :end_date, :time_off_type, :status, presence: true
end

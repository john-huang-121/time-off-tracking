class TimeOffRequest < ApplicationRecord
  belongs_to :user

  enum :time_off_type, { vacation: 0, sick: 1, personal: 2 }, prefix: true
  enum :status, { pending: 0, approved: 1, denied: 2, canceled: 3 }, prefix: true

  validates :start_date, :end_date, presence: true
end
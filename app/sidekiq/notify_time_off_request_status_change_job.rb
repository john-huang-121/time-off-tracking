class NotifyTimeOffRequestStatusChangeJob < ApplicationJob
  queue_as :notifications

  def perform(time_off_request_id, prev_status, new_status)
    TimeOffRequestMailer.request_status_changed(time_off_request_id, prev_status, new_status).deliver_now
  end
end

class TimeOffRequestMailer < ApplicationMailer
  def request_created(time_off_request_id)
    @time_off_request = TimeOffRequest
      .includes(user: { profile: :manager })
      .find(time_off_request_id)

    @requester = @time_off_request.user
    @reviewer  = @requester.manager
    return if @reviewer.blank?

    leave_type = @time_off_request.time_off_type.humanize
    date_range = "#{@time_off_request.start_date.strftime('%b %d, %Y')}–#{@time_off_request.end_date.strftime('%b %d, %Y')}"

    recipients = [ @reviewer.email, @requester.email ].compact

    mail(
      to: recipients,
      subject: "Time-off request pending review: #{leave_type} (#{date_range})"
    )
  end

  def request_status_changed(time_off_request_id, prev_status, new_status)
    @time_off_request = TimeOffRequest
      .includes({ user: { profile: :manager } }, latest_approval: :reviewer)
      .find(time_off_request_id)
    @requester = @time_off_request.user
    @reviewer  = @time_off_request.reviewed_by
    @prev_status = prev_status
    @new_status  = new_status

    return if @reviewer.blank? || @requester.blank?

    leave_type  = @time_off_request.time_off_type.humanize
    date_range  = "#{@time_off_request.start_date.strftime('%b %d, %Y')}–#{@time_off_request.end_date.strftime('%b %d, %Y')}"
    status_text = new_status.to_s.humanize

    recipients = [ @reviewer.email, @requester.email ].compact

    mail(
      to: recipients,
      subject: "Time-off request #{status_text.downcase}: #{leave_type} (#{date_range})"
    )
  end
end

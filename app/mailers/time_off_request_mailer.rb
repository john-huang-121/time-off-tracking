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

    recipients = [@reviewer.email, @requester.email].compact

    mail(
      to: recipients,
      subject: "Time-off request pending review: #{leave_type} (#{date_range})"
    )
  end
end

# Preview all emails at http://localhost:3000/rails/mailers/time_off_request_mailer
class TimeOffRequestMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/time_off_request_mailer/request_created
  def request_created
    TimeOffRequestMailer.request_created(1)
  end
end

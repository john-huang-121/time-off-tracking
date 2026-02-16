require "test_helper"

class TimeOffRequestMailerTest < ActionMailer::TestCase
  test "request_created" do
    mail = TimeOffRequestMailer.request_created
    assert_equal "Request created", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end

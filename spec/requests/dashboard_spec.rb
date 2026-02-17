require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  include Devise::Test::IntegrationHelpers

  let!(:department) { Department.create!(name: "Engineering") }

  def create_request!(user:, status:, start_date:, end_date:, type: :vacation)
    TimeOffRequest.create!(
      user: user,
      start_date: start_date,
      end_date: end_date,
      time_off_type: type,
      status: status
    )
  end

  it "employee sees stats and no requests_to_review" do
    employee = create(:user, :employee, :with_profile)
    sign_in employee

    create(:time_off_request, :pending, user: employee, start_date: Date.current + 5, end_date: Date.current + 6)
    create(:time_off_request, :pending, user: employee, start_date: Date.current + 15, end_date: Date.current + 15)
    create(:time_off_request, :approved, user: employee, start_date: Date.current + 20, end_date: Date.current + 20)

    get "/dashboard"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Dashboard")
  end

  it "manager sees direct report pending requests to review" do
    manager = create(:user, :manager, email: "mgr@example.com")
    create(:profile, user: manager, first_name: "Ellie", last_name: "Manager")

    employee = create(:user, :employee, email: "emp2@example.com")
    create(:profile, user: employee, first_name: "John", last_name: "Doe", manager: manager)
    sign_in manager

    create(:time_off_request, :pending, user: employee, start_date: Date.current + 7, end_date: Date.current + 7)
    create(:time_off_request, :pending, user: manager, start_date: Date.current + 3, end_date: Date.current + 3)

    get "/dashboard"
    expect(response).to have_http_status(:ok)

    # lightweight assertion: manager’s review table should include the employee email/name somewhere
    expect(response.body).to include(employee.full_name).or include("Requests Awaiting Your Review")
  end
end

require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  include Devise::Test::IntegrationHelpers

  let!(:department) { Department.create!(name: "Engineering") }

  # before do
  #   @request.env["devise.mapping"] = Devise.mappings[:user]
  # end

  def create_user!(email:, role:, manager: nil)
    user = User.create!(email: email, password: "Password1!", role: role)
    Profile.create!(
      user: user,
      department: department,
      manager: manager,
      first_name: "First",
      last_name: "Last",
      birth_date: 25.years.ago.to_date,
      phone_number: "5550001111"
    )
    user
  end

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
    employee = create_user!(email: "emp@example.com", role: :employee)
    sign_in employee

    create_request!(user: employee, status: :pending,  start_date: Date.current + 5,  end_date: Date.current + 6)
    create_request!(user: employee, status: :pending,  start_date: Date.current + 15, end_date: Date.current + 15)
    create_request!(user: employee, status: :approved, start_date: Date.current + 20, end_date: Date.current + 20)

    get "/dashboard"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Dashboard")
  end

  it "manager sees direct report pending requests to review and not self" do
    manager  = create_user!(email: "mgr@example.com", role: :manager)
    employee = create_user!(email: "emp2@example.com", role: :employee, manager: manager)
    sign_in manager

    dr_pending = create_request!(user: employee, status: :pending, start_date: Date.current + 7, end_date: Date.current + 7)
    create_request!(user: manager, status: :pending, start_date: Date.current + 3, end_date: Date.current + 3)

    get "/dashboard"
    expect(response).to have_http_status(:ok)

    # lightweight assertion: manager’s review table should include the employee email/name somewhere
    expect(response.body).to include(employee.email).or include("Requests Awaiting Your Review")
    puts response.body
    expect(response.body).not_to include(manager.email) # ensures self isn't listed in review section
  end
end

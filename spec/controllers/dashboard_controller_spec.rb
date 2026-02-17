require "rails_helper"

RSpec.describe DashboardController, type: :controller do
  let!(:department) { Department.create!(name: "Engineering") }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

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

  describe "GET #index" do
    context "as employee" do
      it "sets my pending/upcoming and stats for current year; requests_to_review is none" do
        employee = create_user!(email: "emp@example.com", role: :employee)
        sign_in employee

        # current year
        create_request!(user: employee, status: :pending,  start_date: Date.current + 5,  end_date: Date.current + 6)
        create_request!(user: employee, status: :pending,  start_date: Date.current + 15, end_date: Date.current + 15)
        create_request!(user: employee, status: :approved, start_date: Date.current + 20, end_date: Date.current + 20)

        # last year (should not count in year_scope)
        last_year = Date.current.prev_year
        create_request!(user: employee, status: :approved,
          start_date: last_year.beginning_of_year + 10,
          end_date:   last_year.beginning_of_year + 10
        )

        get :index

        pending = assigns(:pending_requests)
        upcoming = assigns(:upcoming_time_off)
        review = assigns(:requests_to_review)
        stats = assigns(:stats)

        expect(pending).to all(have_attributes(status: "pending"))
        expect(pending.size).to be <= 5

        expect(upcoming).to all(have_attributes(status: "approved"))
        expect(upcoming.size).to be <= 5

        expect(review).to be_empty

        expect(stats[:total_requests]).to eq(3)
        expect(stats[:pending_requests]).to eq(2)
        expect(stats[:approved_requests]).to eq(1)
        expect(stats[:days_used]).to eq(1) # matches your current implementation (count approved)
      end
    end

    context "as manager" do
      it "includes pending direct reports in requests_to_review and excludes self" do
        manager = create_user!(email: "mgr@example.com", role: :manager)
        employee = create_user!(email: "emp2@example.com", role: :employee, manager: manager)
        sign_in manager

        dr_pending = create_request!(
          user: employee,
          status: :pending,
          start_date: Date.current + 7,
          end_date: Date.current + 7
        )

        # manager's own pending request should NOT be reviewable
        create_request!(
          user: manager,
          status: :pending,
          start_date: Date.current + 3,
          end_date: Date.current + 3
        )

        get :index

        review = assigns(:requests_to_review)

        expect(review.map(&:id)).to include(dr_pending.id)
        expect(review.map(&:user_id)).not_to include(manager.id)
      end
    end

    context "as admin" do
      it "can see requests_to_review (pending) in requests_to_review" do
        admin = create_user!(email: "admin@example.com", role: :admin)
        employee = create_user!(email: "emp3@example.com", role: :employee)
        sign_in admin

        pending_req = create_request!(
          user: employee,
          status: :pending,
          start_date: Date.current + 10,
          end_date: Date.current + 10
        )

        get :index

        review = assigns(:requests_to_review)
        expect(review.map(&:id)).to include(pending_req.id)
      end
    end
  end
end

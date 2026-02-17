require "swagger_helper"

RSpec.describe "Dashboard", type: :request do
  include Devise::Test::IntegrationHelpers

  path "/dashboard" do
    get "Dashboard (HTML)" do
      tags "Dashboard"
      produces "text/html"

      response "302", "redirects when unauthenticated" do
        run_test!
      end

      response "200", "renders when authenticated" do
        let!(:dept) { Department.create!(name: "Engineering") }
        let!(:user) do
          User.create!(email: "u2@example.com", password: "Password1!", role: :employee).tap do |u|
            Profile.create!(
              user: u, department: dept,
              first_name: "A", last_name: "B",
              birth_date: 25.years.ago.to_date, phone_number: "5550001111"
            )
          end
        end

        before { sign_in user }

        run_test! do |response|
          expect(response.body).to include("Dashboard")
        end
      end
    end
  end
end

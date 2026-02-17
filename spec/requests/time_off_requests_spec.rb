require "swagger_helper"

RSpec.describe "Time Off Requests", type: :request do
  path "/time_off_requests" do
    get "List all time off requests" do
      tags "Time Off Requests"
      produces "text/html"

      parameter name: :page, in: :query, type: :integer, required: false, description: "Page number"
      parameter name: :status, in: :query, schema: {
        type: :string,
        enum: %w[pending approved denied canceled]
      }

      response "200", "time off requests found" do
        let(:user) { create(:user, :employee, :with_profile) }
        let!(:time_off_request) { create(:time_off_request, user: user) }

        before { sign_in user, scope: :user }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("<title>Time-Off Tracker</title>")
        end
      end

      response "302", "redirects to sign in when unauthenticated" do
        run_test! do |response|
          expect(response).to have_http_status(:found)
          expect(response.headers["Location"]).to include("/users/sign_in")
        end
      end
    end

    post "Create a time off request" do
      tags "Time Off Requests"
      consumes "application/json"
      produces "text/html"

      parameter name: :time_off_request, in: :body, schema: {
        type: :object,
        properties: {
          time_off_request: {
            type: :object,
            properties: {
              start_date: { type: :string, format: :date },
              end_date:   { type: :string, format: :date },
              time_off_type: { type: :string, enum: %w[vacation sick personal] },
              reason: { type: :string, nullable: true }
            },
            required: %w[start_date end_date time_off_type]
          }
        }
      }

      response "302", "time off request created (redirect)" do
        let(:user) { create(:user, :employee, :with_profile) }
        let(:time_off_request) do
          {
            time_off_request: {
              start_date: Date.current + 7.days,
              end_date: Date.current + 9.days,
              time_off_type: "vacation",
              reason: "Family vacation"
            }
          }
        end

        before { sign_in user, scope: :user }

        run_test! do |response|
          expect(response).to have_http_status(:found)
          expect(response.headers["Location"]).to match(%r{/time_off_requests/\d+})
        end
      end

      response "422", "invalid request" do
        let(:user) { create(:user, :employee, :with_profile) }
        let(:time_off_request) do
          {
            time_off_request: {
              start_date: Date.current + 9.days,
              end_date: Date.current + 7.days, # invalid
              time_off_type: "vacation"
            }
          }
        end

        before { sign_in user, scope: :user }

        run_test! do |response|
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      response "302", "redirects to sign in when unauthenticated" do
        let(:time_off_request) { { time_off_request: { start_date: Date.current } } }

        run_test! do |response|
          expect(response).to have_http_status(:found)
          expect(response.headers["Location"]).to include("/users/sign_in")
        end
      end
    end
  end

  path "/time_off_requests/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Time off request ID"

    get "Retrieve a time off request" do
      tags "Time Off Requests"
      produces "text/html"

      response "200", "time off request found" do
        let(:user) { create(:user, :employee, :with_profile) }
        let(:id) { create(:time_off_request, user: user).id }

        before { sign_in user, scope: :user }

        run_test! { |response| expect(response).to have_http_status(:ok) }
      end

      response "404", "time off request not found" do
        let(:user) { create(:user, :employee, :with_profile) }
        let(:id) { 999_999_999 }

        before { sign_in user, scope: :user }

        run_test!
      end

      response "302", "redirects to sign in when unauthenticated" do
        let(:id) { 1 }

        run_test!
      end
    end

    patch "Update a time off request" do
      tags "Time Off Requests"
      consumes "application/json"
      produces "text/html"

      parameter name: :time_off_request, in: :body, schema: {
        type: :object,
        properties: {
          time_off_request: {
            type: :object,
            properties: {
              start_date: { type: :string, format: :date },
              end_date:   { type: :string, format: :date },
              time_off_type: { type: :string, enum: %w[vacation sick personal] },
              reason: { type: :string }
            }
          }
        }
      }

      response "302", "time off request updated (redirect)" do
        let(:user) { create(:user, :employee, :with_profile) }
        let(:id) { create(:time_off_request, user: user).id }
        let(:time_off_request) { { time_off_request: { reason: "Updated reason" } } }

        before { sign_in user, scope: :user }

        run_test! do |response|
          expect(response).to have_http_status(:found)
          expect(response.headers["Location"]).to include("/time_off_requests/#{id}")
        end
      end

      response "422", "invalid request" do
        let(:user) { create(:user, :employee, :with_profile) }
        let(:request_record) { create(:time_off_request, user: user, start_date: Date.current + 10, end_date: Date.current + 12) }
        let(:id) { request_record.id }
        let(:time_off_request) { { time_off_request: { end_date: Date.current - 1.day } } }

        before { sign_in user, scope: :user }

        run_test! { |response| expect(response).to have_http_status(:unprocessable_entity) }
      end
    end

    delete "Delete a time off request" do
      tags "Time Off Requests"
      produces "text/html"

      response "302", "time off request deleted (redirect)" do
        let(:user) { create(:user, :employee, :with_profile) }
        let(:id) { create(:time_off_request, user: user).id }

        before { sign_in user, scope: :user }

        run_test! do |response|
          expect(response).to have_http_status(:found)
          expect(response.headers["Location"]).to include("/time_off_requests")
        end
      end

      response "404", "time off request not found" do
        let(:user) { create(:user, :employee, :with_profile) }
        let(:id) { 999_999_999 }

        before { sign_in user, scope: :user }

        run_test!
      end
    end
  end

  # Member actions (HTML redirects)
  %w[approve deny cancel].each do |action|
    path "/time_off_requests/{id}/#{action}" do
      parameter name: :id, in: :path, type: :integer, description: "Time off request ID"

      post "#{action} a time off request" do
        tags "Time Off Requests"
        consumes "application/json"
        produces "text/html"

        parameter name: :approval, in: :body, schema: {
          type: :object,
          properties: { comment: { type: :string, nullable: true } }
        }

        response "302", "#{action} performed (redirect)" do
          let(:manager) { create(:user, :manager, :with_profile) }
          let(:employee) { create(:user, :employee, :with_profile) }
          let(:id) { create(:time_off_request, user: employee, status: :pending).id }
          let(:approval) { { comment: "OK" } }

          before do
            employee.profile.update!(manager_id: manager.id)

            actor = (action == "cancel") ? employee : manager
            sign_in actor, scope: :user
          end

          run_test! do |response|
            expect(response).to have_http_status(:found)
            expect(response.headers["Location"]).to include("/time_off_requests/#{id}")
          end
        end
      end
    end
  end
end

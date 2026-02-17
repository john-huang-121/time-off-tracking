# spec/requests/profiles_spec.rb
require "rails_helper"

RSpec.describe "Profiles", type: :request do
  include Devise::Test::IntegrationHelpers

  # Belt + suspenders if you’ve ever seen Devise.mappings empty in specs
  before { Rails.application.reload_routes! }

  let!(:department) { create(:department, name: "Engineering") }
  let!(:manager_user) { create(:user, :manager, email: "mgr@example.com") }
  let!(:admin_user)   { create(:user, :admin,   email: "admin@example.com") }

  let(:user) { create(:user, :employee, email: "emp@example.com") }

  let(:valid_profile_params) do
    {
      profile: {
        first_name: "John",
        last_name: "Doe",
        birth_date: 25.years.ago.to_date,
        phone_number: "5550001111",
        department_id: department.id,
        manager_id: manager_user.id
      }
    }
  end

  describe "GET /users/:user_id/profile/new" do
    it "redirects to sign in when unauthenticated" do
      get new_user_profile_path(user)
      expect(response).to have_http_status(:found)
      expect(response.headers["Location"]).to include("/users/sign_in")
    end

    it "renders the form and includes dropdown options when authenticated" do
      sign_in user, scope: :user

      get new_user_profile_path(user)
      expect(response).to have_http_status(:ok)

      # proves load_dropdowns ran (departments/managers present in HTML)
      expect(response.body).to include("Engineering")
      expect(response.body).to include("mgr@example.com")
      expect(response.body).to include("admin@example.com")
    end
  end

  describe "POST /users/:user_id/profile" do
    it "creates/saves the profile and redirects to show" do
      sign_in user, scope: :user

      expect {
        post user_profile_path(user), params: valid_profile_params
      }.to change(Profile, :count).by(1)

      expect(response).to have_http_status(:found)
      expect(response.headers["Location"]).to eq(user_profile_url(user))

      user.reload
      expect(user.profile).to be_present
      expect(user.profile.first_name).to eq("John")
      expect(user.profile.department_id).to eq(department.id)
      expect(user.profile.manager_id).to eq(manager_user.id)
    end

    it "re-renders new with 422 when invalid" do
      sign_in user, scope: :user

      invalid = valid_profile_params.deep_dup
      invalid[:profile][:first_name] = nil

      expect {
        post user_profile_path(user), params: invalid
      }.not_to change(Profile, :count)

      expect(response).to have_http_status(:unprocessable_entity)

      # load_dropdowns should still run for create failures
      expect(response.body).to include("Engineering")
      expect(response.body).to include("mgr@example.com")
    end
  end

  describe "GET /users/:user_id/profile/edit" do
    it "renders edit" do
      sign_in user, scope: :user
      create(:profile, user: user, department: department, manager: manager_user)

      get edit_user_profile_path(user)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /users/:user_id/profile" do
    it "updates and redirects to show" do
      sign_in user, scope: :user
      create(:profile, user: user, department: department, manager: manager_user)

      patch user_profile_path(user), params: { profile: { phone_number: "5559990000" } }

      expect(response).to have_http_status(:found)
      expect(response.headers["Location"]).to eq(user_profile_url(user))

      expect(user.reload.profile.phone_number).to eq("5559990000")
    end

    it "re-renders edit with 422 when invalid" do
      sign_in user, scope: :user
      create(:profile, user: user, department: department, manager: manager_user)

      patch user_profile_path(user), params: { profile: { last_name: nil } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.profile.last_name).not_to be_nil
    end
  end

  describe "GET /users/:user_id/profile" do
    it "shows the profile" do
      sign_in user, scope: :user
      create(:profile, user: user, department: department, manager: manager_user,
                       first_name: "John", last_name: "Doe")

      get user_profile_path(user)
      expect(response).to have_http_status(:ok)

      # light assertion that the page is for this user
      expect(response.body).to include("John")
      expect(response.body).to include("Doe")
    end
  end
end

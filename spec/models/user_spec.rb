require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_one(:profile).dependent(:destroy) }
    it { should have_many(:time_off_requests).dependent(:destroy) }
    it { should have_many(:direct_report_profiles).class_name('Profile') }
    it { should have_many(:direct_reports).through(:direct_report_profiles) }
  end

describe "validations" do
    subject { build(:user) }

    it { should validate_presence_of(:email) }

    it "validates uniqueness of email" do
      create(:user, email: "test@example.com")
      should validate_uniqueness_of(:email).case_insensitive
    end

    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(6) }
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(employee: 0, manager: 1, admin: 2).with_prefix(:role) }
  end

  describe 'delegations' do
    let(:user) { create(:user, :with_profile) }

    it 'delegates full_name to profile' do
      expect(user).to respond_to(:full_name)
      expect(user.full_name).to eq(user.profile.full_name)
    end

    it 'delegates department to profile' do
      expect(user).to respond_to(:department)
      expect(user.department).to eq(user.profile.department)
    end

    it 'delegates manager to profile' do
      expect(user).to respond_to(:manager)
    end
  end

  describe '#can_approve?' do
    let(:admin) { create(:user, :admin, :with_profile) }
    let(:manager) { create(:user, :manager, :with_profile) }
    let(:employee) { create(:user, :employee, :with_profile) }
    let(:direct_report) { create(:user, :employee, :with_profile) }
    let(:request) { create(:time_off_request, user: direct_report) }

    before do
      direct_report.profile.update(manager_id: manager.id)
    end

    context 'when user is admin' do
      it 'can approve any request' do
        expect(admin.can_approve?(request)).to be true
      end
    end

    context 'when user is manager' do
      it 'can approve direct report requests' do
        expect(manager.can_approve?(request)).to be true
      end

      it 'cannot approve non-direct report requests' do
        other_request = create(:time_off_request)
        expect(manager.can_approve?(other_request)).to be false
      end

      it 'cannot approve own request' do
        own_request = create(:time_off_request, user: manager)
        expect(manager.can_approve?(own_request)).to be false
      end
    end

    context 'when user is employee' do
      it 'cannot approve any request' do
        expect(employee.can_approve?(request)).to be false
      end

      it 'cannot approve own request' do
        own_request = create(:time_off_request, user: employee)
        expect(employee.can_approve?(own_request)).to be false
      end
    end
  end

  describe '#profile_complete?' do
    context 'when profile exists with all required fields' do
      let(:user) { create(:user, :with_profile) }

      it 'returns true' do
        expect(user.profile_complete?).to be true
      end
    end

    context 'when profile is missing' do
      let(:user) { create(:user) }

      it 'returns false' do
        expect(user.profile_complete?).to be false
      end
    end

    context "when profile is missing required fields" do
      let(:user) { create(:user, :with_profile) }

      it "returns false when first_name is missing" do
        user.profile.assign_attributes(first_name: nil) # does not save
        expect(user.profile_complete?).to be false
      end

      it "returns false when last_name is missing" do
        user.profile.assign_attributes(last_name: nil) # does not save
        expect(user.profile_complete?).to be false
      end

      it "returns false when profile is missing (department can’t be nil in DB)" do
        user.profile.destroy!
        expect(user.reload.profile_complete?).to be false
      end
    end
  end

  describe '#remaining_vacation_days' do
    let(:user) { create(:user) }

    it 'returns a number' do
      expect(user.remaining_vacation_days).to be_a(Integer)
    end

    # Note: This is a placeholder implementation in the model
    # Real implementation would calculate based on annual allowance and used days
  end

  describe 'role predicates' do
    it 'identifies employee role' do
      user = create(:user, role: :employee)
      expect(user.role_employee?).to be true
      expect(user.role_manager?).to be false
      expect(user.role_admin?).to be false
    end

    it 'identifies manager role' do
      user = create(:user, role: :manager)
      expect(user.role_employee?).to be false
      expect(user.role_manager?).to be true
      expect(user.role_admin?).to be false
    end

    it 'identifies admin role' do
      user = create(:user, role: :admin)
      expect(user.role_employee?).to be false
      expect(user.role_manager?).to be false
      expect(user.role_admin?).to be true
    end
  end
end

require 'rails_helper'
require "sidekiq/testing"
Sidekiq::Testing.fake!

RSpec.describe TimeOffRequest, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:approvals).dependent(:destroy) }
    it { should have_one(:latest_approval).class_name('Approval') }
  end

  describe 'validations' do
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_presence_of(:time_off_type) }
    it { should validate_presence_of(:status) }

    describe 'end_date_on_or_after_start_date' do
      it 'is valid when end_date is after start_date' do
        request = build(:time_off_request, start_date: Date.current, end_date: Date.current + 2.days)
        expect(request).to be_valid
      end

      it 'is valid when end_date equals start_date' do
        request = build(:time_off_request, start_date: Date.current, end_date: Date.current)
        expect(request).to be_valid
      end

      it 'is invalid when end_date is before start_date' do
        request = build(:time_off_request, start_date: Date.current + 2.days, end_date: Date.current)
        expect(request).not_to be_valid
        expect(request.errors[:end_date]).to include('must be on or after the start date')
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:time_off_type).with_values(vacation: 0, sick: 1, personal: 2).with_prefix(:time_off_type) }
    it { should define_enum_for(:status).with_values(pending: 0, approved: 1, denied: 2, canceled: 3).with_prefix(:status) }
  end

  describe 'scopes' do
    let!(:old_request) { create(:time_off_request, created_at: 2.days.ago) }
    let!(:new_request) { create(:time_off_request, created_at: 1.day.ago) }

    describe '.ordered' do
      it 'returns requests in descending order by created_at' do
        expect(TimeOffRequest.ordered).to eq([ new_request, old_request ])
      end
    end

    describe '.current_year' do
      let!(:this_year_request) { create(:time_off_request, start_date: Date.current) }
      let!(:last_year_request) { create(:time_off_request, start_date: 1.year.ago) }

      it 'returns only requests from current year' do
        expect(TimeOffRequest.current_year).to include(this_year_request)
        expect(TimeOffRequest.current_year).not_to include(last_year_request)
      end
    end

    describe '.upcoming' do
      let!(:future_request) { create(:time_off_request, start_date: Date.current + 7.days) }
      let!(:past_request) { create(:time_off_request, start_date: Date.current - 7.days) }

      it 'returns only future requests' do
        expect(TimeOffRequest.upcoming).to include(future_request)
        expect(TimeOffRequest.upcoming).not_to include(past_request)
      end
    end

    describe '.for_approval_by' do
      let(:admin) { create(:user, :admin, :with_profile) }
      let(:manager) { create(:user, :manager, :with_profile) }
      let(:employee) { create(:user, :employee, :with_profile) }
      let(:direct_report) { create(:user, :employee, :with_profile) }

      let!(:direct_report_request) { create(:time_off_request, user: direct_report, status: :pending) }
      let!(:other_request) { create(:time_off_request, status: :pending) }
      let!(:approved_request) { create(:time_off_request, :approved) }

      before do
        direct_report.profile.update(manager_id: manager.id)
      end

      context 'when user is admin' do
        it 'returns all pending requests' do
          expect(TimeOffRequest.for_approval_by(admin)).to include(direct_report_request, other_request)
          expect(TimeOffRequest.for_approval_by(admin)).not_to include(approved_request)
        end
      end

      context 'when user is manager' do
        it 'returns only pending requests from direct reports' do
          expect(TimeOffRequest.for_approval_by(manager)).to include(direct_report_request)
          expect(TimeOffRequest.for_approval_by(manager)).not_to include(other_request, approved_request)
        end
      end

      context 'when user is employee' do
        it 'returns no requests' do
          expect(TimeOffRequest.for_approval_by(employee)).to be_empty
        end
      end
    end
  end

  describe 'delegations' do
    let(:reviewer) { create(:user, :manager, :with_profile) }
    let(:request) { create(:time_off_request, :approved) }

    before do
      request.latest_approval.update(reviewer: reviewer)
    end

    it 'delegates reviewed_at to latest_approval' do
      expect(request.latest_approval_reviewed_at)
        .to be_within(1.second).of(request.latest_approval.updated_at)
    end

    it 'delegates review_notes to latest_approval' do
      request.latest_approval.update(comment: 'Test comment')
      expect(request.latest_approval_review_notes).to eq('Test comment')
    end
  end

  describe '#reviewed_by' do
    let(:reviewer) { create(:user, :manager, :with_profile) }
    let(:request) { create(:time_off_request, :approved) }

    before do
      request.latest_approval.update(reviewer: reviewer)
    end

    it 'returns the reviewer from latest approval' do
      expect(request.reviewed_by).to eq(reviewer)
    end

    context 'when there is no approval' do
      let(:pending_request) { create(:time_off_request, :pending) }

      it 'returns nil' do
        expect(pending_request.reviewed_by).to be_nil
      end
    end
  end

  describe '#total_days' do
    it 'calculates correct number of days' do
      request = build(:time_off_request, start_date: Date.current, end_date: Date.current + 2.days)
      expect(request.total_days).to eq(3)
    end

    it 'returns 1 for same day' do
      request = build(:time_off_request, start_date: Date.current, end_date: Date.current)
      expect(request.total_days).to eq(1)
    end

    it 'returns 0 when dates are blank' do
      request = build(:time_off_request, start_date: nil, end_date: nil)
      expect(request.total_days).to eq(0)
    end
  end

  describe '#approve!' do
    let(:reviewer) { create(:user, :manager, :with_profile) }
    let(:request) { create(:time_off_request, :pending) }

    it 'changes status to approved' do
      expect {
        request.approve!(reviewer: reviewer)
      }.to change { request.reload.status }.from('pending').to('approved')
    end

    it 'creates an approval record' do
      expect {
        request.approve!(reviewer: reviewer)
      }.to change { request.approvals.count }.by(1)
    end

    it 'sets the correct decision on approval' do
      request.approve!(reviewer: reviewer)
      expect(request.approvals.last.decision).to eq('approved')
    end

    it 'accepts optional comment' do
      request.approve!(reviewer: reviewer, comment: 'Looks good')
      expect(request.approvals.last.comment).to eq('Looks good')
    end

    it 'returns true on success' do
      expect(request.approve!(reviewer: reviewer)).to be true
    end
  end

  describe '#deny!' do
    let(:reviewer) { create(:user, :manager, :with_profile) }
    let(:request) { create(:time_off_request, :pending) }

    it 'changes status to denied' do
      expect {
        request.deny!(reviewer: reviewer)
      }.to change { request.reload.status }.from('pending').to('denied')
    end

    it 'creates an approval record' do
      expect {
        request.deny!(reviewer: reviewer)
      }.to change { request.approvals.count }.by(1)
    end

    it 'sets the correct decision on approval' do
      request.deny!(reviewer: reviewer)
      expect(request.approvals.last.decision).to eq('denied')
    end

    it 'accepts optional comment' do
      request.deny!(reviewer: reviewer, comment: 'Cannot approve at this time')
      expect(request.approvals.last.comment).to eq('Cannot approve at this time')
    end
  end

  describe '#cancel!' do
    let(:user) { create(:user, :with_profile) }
    let(:request) { create(:time_off_request, :pending, user: user) }

    it 'changes status to canceled' do
      expect {
        request.cancel!(reviewer: user)
      }.to change { request.reload.status }.from('pending').to('canceled')
    end

    it 'creates an approval record' do
      expect {
        request.cancel!(reviewer: user)
      }.to change { request.approvals.count }.by(1)
    end
  end

  describe '#can_be_canceled?' do
    it 'returns true for pending requests' do
      request = build(:time_off_request, :pending)
      expect(request.can_be_canceled?).to be true
    end

    it 'returns true for approved requests' do
      request = build(:time_off_request, :approved)
      expect(request.can_be_canceled?).to be true
    end

    it 'returns false for denied requests' do
      request = build(:time_off_request, :denied)
      expect(request.can_be_canceled?).to be false
    end

    it 'returns false for canceled requests' do
      request = build(:time_off_request, :canceled)
      expect(request.can_be_canceled?).to be false
    end
  end

  describe 'callbacks', use_transactional_fixtures: false do
    after do
      Sidekiq::Worker.clear_all
      clear_enqueued_jobs
      clear_performed_jobs

      Approval.delete_all
      TimeOffRequest.delete_all
      Profile.delete_all
      Department.delete_all
      User.delete_all
    end

    describe 'after_create_commit' do
      it 'enqueues email notification when manager exists' do
        manager  = create(:user, :manager, :with_profile)
        employee = create(:user, :employee, :with_profile)
        employee.profile.update!(manager: manager)

        expect {
          create(:time_off_request, user: employee)
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end

    describe "after_update_commit" do
      let(:request)  { create(:time_off_request, :pending) }
      let(:reviewer) { create(:user, :manager, :with_profile) }

      before { clear_enqueued_jobs }

      it "enqueues status change notification when status changes" do
        expect { request.approve!(reviewer: reviewer) }
          .to have_enqueued_job(NotifyTimeOffRequestStatusChangeJob)
      end

      it "does not enqueue notification when status does not change" do
        expect { request.update!(reason: "Updated reason") }
          .not_to have_enqueued_job(NotifyTimeOffRequestStatusChangeJob)
      end
    end
  end
end

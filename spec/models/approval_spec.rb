require 'rails_helper'

RSpec.describe Approval, type: :model do
  describe 'associations' do
    it { should belong_to(:time_off_request) }
    it { should belong_to(:reviewer).class_name('User') }
  end

  describe 'validations' do
    it { should validate_presence_of(:decision) }
  end

  describe 'enums' do
    it 'defines decision enum' do
      approval = build(:approval)

      expect(approval).to respond_to(:decision)
      expect(approval).to respond_to(:decision_approved?)
      expect(approval).to respond_to(:decision_denied?)
      expect(approval).to respond_to(:decision_canceled?)
    end
  end

  describe 'creation' do
    it 'stores decision correctly' do
      approval = create(:approval, decision: :approved)
      expect(approval.reload.decision).to eq('approved')
      expect(approval.decision_approved?).to be true
    end
  end
end

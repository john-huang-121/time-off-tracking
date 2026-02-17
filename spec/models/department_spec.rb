require 'rails_helper'

RSpec.describe Department, type: :model do
  describe 'associations' do
    it { should have_many(:profiles) }
  end

  describe "validations" do
    subject { create(:department) } # helps uniqueness matcher

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe 'creation' do
    it 'creates a valid department' do
      department = build(:department)
      expect(department).to be_valid
      expect(department.save).to be true
    end

    it 'does not allow duplicate names' do
      create(:department, name: 'Engineering')
      duplicate = build(:department, name: 'Engineering')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end
  end
end

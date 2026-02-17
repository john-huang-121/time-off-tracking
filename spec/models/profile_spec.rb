require 'rails_helper'

RSpec.describe Profile, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:department) }
    it { should belong_to(:manager).class_name('User').optional }
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      profile = create(:profile, :with_department)
      expect(profile).to be_valid
    end
  end

  describe '#full_name' do
    it 'combines first and last name' do
      profile = build(:profile, first_name: 'John', last_name: 'Doe')
      expect(profile.full_name).to eq('John Doe')
    end
  end
end

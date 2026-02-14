class Profile < ApplicationRecord
  belongs_to :user, inverse_of: :profile
  belongs_to :department, optional: true
  belongs_to :manager, class_name: "User", optional: true, inverse_of: :direct_report_profiles

  validates :first_name, :last_name, :birth_date, :phone_number, presence: true
  validates :user_id, uniqueness: true
  validate :manager_cannot_be_self
  validate :manager_chain_cannot_cycle

  private

  def manager_cannot_be_self
    return if manager_id.blank? || user_id.blank?
    errors.add(:manager_id, "cannot be yourself") if manager_id == user_id
  end

  # Lightweight cycle prevention for a single-chain hierarchy
  def manager_chain_cannot_cycle
    return if manager.nil? || user.nil?

    seen = Set.new([user_id])
    cursor = manager

    while cursor
      return errors.add(:manager_id, "creates a management cycle") if seen.include?(cursor.id)
      seen.add(cursor.id)
      cursor = cursor.profile&.manager
    end
  end
end
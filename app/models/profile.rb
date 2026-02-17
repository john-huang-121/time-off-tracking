class Profile < ApplicationRecord
  MIN_AGE_YEARS = 14

  belongs_to :user, inverse_of: :profile
  belongs_to :department, inverse_of: :profiles
  belongs_to :manager, class_name: "User", optional: true, inverse_of: :direct_report_profiles

  validates :first_name, :last_name, :birth_date, :phone_number, :department_id, presence: true
  validates :user_id, uniqueness: true
  validate :birth_date_cannot_be_in_future
  validate :at_least_minimum_age
  validate :manager_cannot_be_self
  validate :manager_chain_cannot_cycle

  def full_name
    [ first_name, last_name ].compact.join(" ").strip
  end

  private

  def at_least_minimum_age
    return if birth_date.blank?

    cutoff = Date.current - MIN_AGE_YEARS.years
    return if birth_date <= cutoff

    errors.add(:birth_date, "must be at least #{MIN_AGE_YEARS} years old")
  end

  def birth_date_cannot_be_in_future
    return if birth_date.blank?
    errors.add(:birth_date, "cannot be in the future") if birth_date >= Date.current
  end

  def manager_cannot_be_self
    return if manager_id.blank? || user_id.blank?
    errors.add(:manager_id, "cannot be yourself") if manager_id == user_id
  end

  # Lightweight cycle prevention for a single-chain hierarchy
  def manager_chain_cannot_cycle
    return if manager.nil? || user.nil?

    seen = Set.new([ user_id ])
    cursor = manager

    while cursor
      return errors.add(:manager_id, "creates a management cycle") if seen.include?(cursor.id)
      seen.add(cursor.id)
      cursor = cursor.profile&.manager
    end
  end
end

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  enum :role, { employee: 0, manager: 1, admin: 2 }

  has_one :profile, dependent: :destroy, inverse_of: :user

  # Direct reports (users whose profile.manager_id == this user's id)
  has_many :direct_report_profiles,
            class_name: "Profile",
            foreign_key: :manager_id,
            inverse_of: :manager,
            dependent: :nullify
  has_many :direct_reports, through: :direct_report_profiles, source: :user

  # Convenience
  delegate :name, :department, :manager, to: :profile, allow_nil: true

  def profile_complete?
    profile.present? &&
      profile.department_id.present? &&
      profile.first_name.present? &&
      profile.last_name.present?
  end
end
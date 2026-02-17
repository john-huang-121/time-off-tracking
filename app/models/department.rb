class Department < ApplicationRecord
  has_many :profiles

  validates :name, presence: true, uniqueness: true
end

class TimeOffRequestPolicy < ApplicationPolicy
  def index?
    true # All authenticated users can view time-off requests
  end

  def show?
    user.admin? || record.user == user || user.can_approve?(record)
  end

  def create?
    true # All employees can create requests
  end

  def update?
    record.user == user && record.can_be_edited?
  end

  def destroy?
    record.user == user && record.can_be_cancelled?
  end

  def approve?
    user.can_approve?(record) && record.can_be_approved?
  end

  def deny?
    user.can_approve?(record) && record.can_be_denied?
  end

  def cancel?
    record.user == user && record.can_be_cancelled?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.manager?
        # Managers see their own requests + their direct reports' requests
        scope.where(user_id: user.id)
             .or(scope.joins(:user).where(users: { manager_id: user.id }))
      else
        # Employees see only their own requests
        scope.where(user_id: user.id)
      end
    end
  end
end

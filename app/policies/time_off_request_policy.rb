class TimeOffRequestPolicy < ApplicationPolicy
  def index?
    true # All authenticated users can view time-off requests
  end

  def show?
    user.role_admin? || record.user == user || user.can_approve?(record)
  end

  def create?
    true # All employees can create requests
  end

  def update?
    record.user == user && record.status_pending?
  end

  def destroy?
    record.user == user && (record.status_pending? || record.status_approved?)
  end

  def approve?
    user.can_approve?(record) && record.status_pending?
  end

  def deny?
    user.can_approve?(record) && record.status_pending?
  end

  def cancel?
    record.user == user && record.status_pending?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.role_admin?
        scope.all
      elsif user.role_manager?
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

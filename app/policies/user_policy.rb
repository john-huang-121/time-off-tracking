class UserPolicy < ApplicationPolicy
  def index?
    user.admin? || user.manager?
  end

  def show?
    user.admin? || user.manager? || record == user
  end

  def create?
    user.admin?
  end

  def update?
    user.admin? || record == user
  end

  def destroy?
    user.admin? && record != user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.manager?
        # Managers see their direct reports + themselves
        scope.where(manager_id: user.id).or(scope.where(id: user.id))
      else
        # Employees see only themselves
        scope.where(id: user.id)
      end
    end
  end
end

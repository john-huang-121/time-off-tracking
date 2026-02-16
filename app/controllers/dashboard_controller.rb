class DashboardController < ApplicationController
  def index
    # Base relation for "my requests"
    my_requests = current_user.time_off_requests.ordered

    @pending_requests  = my_requests.status_pending.limit(5)
    @upcoming_time_off = my_requests.status_approved.upcoming.limit(5)

    @remaining_vacation_days = current_user.remaining_vacation_days

    @requests_to_review =
      if current_user.role_manager? || current_user.role_admin?
        TimeOffRequest
          .for_approval_by(current_user)
          .includes(user: :profile)
          .ordered
          .limit(10)
      else
        TimeOffRequest.none
      end

    # Stats (avoid repeating similar scopes)
    year_scope = my_requests.current_year.unscope(:order)

    status_counts = year_scope.group(:status).count

    @stats = {
      total_requests:    year_scope.count,
      approved_requests: status_counts.fetch("approved", 0),
      pending_requests:  status_counts.fetch("pending", 0),
      days_used:         year_scope.status_approved.count
    }
  end
end

class DashboardController < ApplicationController
  def index
    # @pending_requests = current_user.time_off_requests.pending.ordered.limit(5)
    # @upcoming_time_off = current_user.time_off_requests.approved.upcoming.limit(5)
    # @remaining_vacation_days = current_user.remaining_vacation_days
    
    if current_user.manager? || current_user.admin?
      # @requests_to_review = TimeOffRequest.for_approval_by(current_user).ordered.limit(10)
      @requests_to_review = []
    end
    
    @stats = {
      # total_requests: current_user.time_off_requests.current_year.count,
      # approved_requests: current_user.time_off_requests.current_year.approved.count,
      # pending_requests: current_user.time_off_requests.pending.count,
      # days_used: current_user.annual_vacation_days - @remaining_vacation_days
      total_requests: 5,
      approved_requests: 5,
      pending_requests: 5,
      days_used: 5,
    }
  end
end
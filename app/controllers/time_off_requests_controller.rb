class TimeOffRequestsController < ApplicationController
  before_action :set_time_off_request, only: [:show, :edit, :update, :destroy, :approve, :deny, :cancel]
  before_action :authorize_request, only: [:show, :edit, :update, :destroy, :approve, :deny, :cancel]

  def index
    @time_off_requests = policy_scope(TimeOffRequest).ordered.page(params[:page]).per(20)
    
    # Filter by status
    @time_off_requests = @time_off_requests.where(status: params[:status]) if params[:status].present?
    
    # Filter by user for managers/admins
    if params[:user_id].present? && (current_user.admin? || current_user.manager?)
      @time_off_requests = @time_off_requests.where(user_id: params[:user_id])
    end
  end

  def show
    @approvals = @time_off_request.approvals.ordered
  end

  def new
    @time_off_request = current_user.time_off_requests.build
    @time_off_types = TimeOffType.active.ordered
    authorize @time_off_request
  end

  def create
    @time_off_request = current_user.time_off_requests.build(time_off_request_params)
    authorize @time_off_request

    if @time_off_request.save
      TimeOffRequestMailer.request_created(@time_off_request).deliver_later
      redirect_to @time_off_request, notice: 'Time-off request was successfully created.'
    else
      @time_off_types = TimeOffType.active.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @time_off_types = TimeOffType.active.ordered
  end

  def update
    if @time_off_request.update(time_off_request_params)
      redirect_to @time_off_request, notice: 'Time-off request was successfully updated.'
    else
      @time_off_types = TimeOffType.active.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @time_off_request.destroy
    redirect_to time_off_requests_url, notice: 'Time-off request was successfully deleted.'
  end

  def approve
    if @time_off_request.approve!(current_user, notes: params[:notes])
      redirect_to @time_off_request, notice: 'Time-off request approved successfully.'
    else
      redirect_to @time_off_request, alert: 'Unable to approve time-off request.'
    end
  end

  def deny
    if @time_off_request.deny!(current_user, notes: params[:notes])
      redirect_to @time_off_request, notice: 'Time-off request denied.'
    else
      redirect_to @time_off_request, alert: 'Unable to deny time-off request.'
    end
  end

  def cancel
    if @time_off_request.cancel!
      redirect_to @time_off_request, notice: 'Time-off request cancelled.'
    else
      redirect_to @time_off_request, alert: 'Unable to cancel time-off request.'
    end
  end

  private

  def set_time_off_request
    @time_off_request = TimeOffRequest.find(params[:id])
  end

  def authorize_request
    authorize @time_off_request
  end

  def time_off_request_params
    params.require(:time_off_request).permit(
      :time_off_type_id,
      :start_date,
      :end_date,
      :reason
    )
  end
end

class TimeOffRequestsController < ApplicationController
  before_action :set_time_off_request, only: %i[show edit update destroy approve deny cancel]
  before_action :authorize_request,    only: %i[show edit update destroy approve deny cancel]
  before_action :load_form_options,    only: %i[new create edit update]

  def index
    scope = policy_scope(TimeOffRequest).ordered

    scope = scope.where(status: params[:status]) if params[:status].present?

    if params[:user_id].present? && (current_user.role_admin? || current_user.role_manager?)
      scope = scope.where(user_id: params[:user_id])
    end

    @time_off_requests = scope.page(params[:page]).per(20)
  end

  def show
    @approvals = @time_off_request.approvals.ordered
  end

  def new
    @time_off_request = current_user.time_off_requests.build
    authorize @time_off_request
  end

  def create
    @time_off_request = current_user.time_off_requests.build(time_off_request_params)
    authorize @time_off_request

    if @time_off_request.save
      redirect_to @time_off_request, notice: "Time-off request was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @time_off_request.update(time_off_request_params)
      redirect_to @time_off_request, notice: "Time-off request was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @time_off_request.destroy
    redirect_to time_off_requests_url, notice: "Time-off request was successfully deleted."
  end

  def approve
    notes = params.dig(:approval, :notes) || params[:notes]
    if @time_off_request.approve!(reviewer: current_user, notes: notes)
      redirect_to @time_off_request, notice: "Time-off request approved successfully."
    else
      redirect_to @time_off_request, alert: "Unable to approve time-off request."
    end
  end

  def deny
    notes = params.dig(:approval, :notes) || params[:notes]
    if @time_off_request.deny!(reviewer: current_user, notes: notes)
      redirect_to @time_off_request, notice: "Time-off request denied."
    else
      redirect_to @time_off_request, alert: "Unable to deny time-off request."
    end
  end

  def cancel
    notes = params.dig(:approval, :notes) || params[:notes]
    if @time_off_request.cancel!(reviewer: current_user, notes: notes)
      redirect_to @time_off_request, notice: "Time-off request cancelled."
    else
      redirect_to @time_off_request, alert: "Unable to cancel time-off request."
    end
  end

  private

  def set_time_off_request
    # IMPORTANT: scope the find to what the user is allowed to see
    @time_off_request = policy_scope(TimeOffRequest).find(params[:id])
  end

  def authorize_request
    authorize @time_off_request
  end

  def load_form_options
    @time_off_types = TimeOffRequest.time_off_types.keys
  end

  def time_off_request_params
    params.require(:time_off_request).permit(
      :time_off_type,
      :start_date,
      :end_date,
      :reason
    )
  end
end

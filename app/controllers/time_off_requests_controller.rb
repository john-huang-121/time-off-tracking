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

    respond_to do |format|
      format.html
      format.json { render json: { time_off_requests: @time_off_requests } }
    end
  end

  def show
    @approvals = @time_off_request.approvals.ordered

    respond_to do |format|
      format.html
      format.json { render json: { time_off_request: @time_off_request } }
    end
  end

  def new
    @time_off_request = current_user.time_off_requests.build
    authorize @time_off_request
  end

  def create
    @time_off_request = current_user.time_off_requests.build(time_off_request_params)
    authorize @time_off_request

    if @time_off_request.save
      respond_to do |format|
        format.html { redirect_to @time_off_request, notice: "Time-off request was successfully created." }
        format.json { render json: { time_off_request: @time_off_request }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @time_off_request.errors }, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @time_off_request.update(time_off_request_params)
      respond_to do |format|
        format.html { redirect_to @time_off_request, notice: "Time-off request was successfully updated." }
        format.json { render json: { time_off_request: @time_off_request } }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @time_off_request.errors }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @time_off_request.destroy

    respond_to do |format|
      format.html { redirect_to time_off_requests_url, notice: "Time-off request was successfully deleted." }
      format.json { head :no_content }
    end
  end

  def approve
    comment = approval_comment
    if @time_off_request.approve!(reviewer: current_user, comment: comment)
      respond_to do |format|
        format.html { redirect_to @time_off_request, notice: "Time-off request approved successfully." }
        format.json { render json: { time_off_request: @time_off_request, message: "Request approved" } }
      end
    else
      respond_to do |format|
        format.html { redirect_to @time_off_request, alert: "Unable to approve time-off request." }
        format.json { render json: { error: "Unable to approve request" }, status: :unprocessable_entity }
      end
    end
  end

  def deny
    comment = approval_comment
    if @time_off_request.deny!(reviewer: current_user, comment: comment)
      respond_to do |format|
        format.html { redirect_to @time_off_request, notice: "Time-off request denied." }
        format.json { render json: { time_off_request: @time_off_request, message: "Request denied" } }
      end
    else
      respond_to do |format|
        format.html { redirect_to @time_off_request, alert: "Unable to deny time-off request." }
        format.json { render json: { error: "Unable to deny request" }, status: :unprocessable_entity }
      end
    end
  end

  def cancel
    comment = approval_comment
    if @time_off_request.cancel!(reviewer: current_user, comment: comment)
      respond_to do |format|
        format.html { redirect_to @time_off_request, notice: "Time-off request canceled." }
        format.json { render json: { time_off_request: @time_off_request, message: "Request canceled" } }
      end
    else
      respond_to do |format|
        format.html { redirect_to @time_off_request, alert: "Unable to cancel time-off request." }
        format.json { render json: { error: "Unable to cancel request" }, status: :unprocessable_entity }
      end
    end
  end

  private

  def approval_comment
    params.dig(:approval, :comment) || params[:comment]
  end

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

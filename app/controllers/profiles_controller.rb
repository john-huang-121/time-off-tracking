class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_dropdowns, only: %i[new edit create update]

  def new
    @profile = current_user.profile || current_user.build_profile
  end

  def create
    @profile = current_user.profile || current_user.build_profile

    if @profile.update(profile_params)
      redirect_to user_profile_path(current_user), notice: "Profile saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @profile = current_user.profile || current_user.build_profile
  end

  def update
    @profile = current_user.profile
    if @profile.update(profile_params)
      redirect_to user_profile_path(current_user), notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    @profile = current_user.profile
  end

  private

  def load_dropdowns
    @departments = Department.order(:name)
    @managers    = User.where(role: %i[manager admin]).order(:email)
  end

  def profile_params
    params.require(:profile).permit(
      :first_name, :last_name, :birth_date, :phone_number,
      :department_id, :manager_id
    )
  end
end

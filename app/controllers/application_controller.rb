class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :redirect_incomplete_profile

  private

  def redirect_incomplete_profile
    return unless user_signed_in?
    return if devise_controller?
    return if controller_name == "profiles" # avoid redirect loop
    return if current_user.profile_complete?

    redirect_to new_user_profile_path(current_user)
  end
end

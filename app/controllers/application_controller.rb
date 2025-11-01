class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  # Redirect user to Expense dashboard after login
  allow_browser versions: :modern
  def after_sign_in_path_for(resource)
    expenses_path
  end

  # Optional: redirect to login after logout
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def not_found
    # This will trigger authentication check
    # If user is not authenticated, they'll be redirected to login
    # If user is authenticated but page doesn't exist, show 404
    if user_signed_in?
      redirect_to root_path, alert: "Page not found"
    else
      # Let Devise handle the redirect to login
      authenticate_user!
    end
  end
end

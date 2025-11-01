class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  # Redirects authenticated users to expenses page after login
  def after_sign_in_path_for(resource)
    expenses_path
  end

  # Redirects users to login page after logout
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end

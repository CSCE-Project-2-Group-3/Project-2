class ApplicationController < ActionController::Base
  # Redirect user to Expense dashboard after login
  allow_browser versions: :modern
  def after_sign_in_path_for(resource)
    expenses_path
  end

  # Optional: redirect to login after logout
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end

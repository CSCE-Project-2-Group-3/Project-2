class ExpensesController < ApplicationController
  before_action :authenticate_user!

  def index
    @expenses = current_user.expenses.order(created_at: :desc).limit(50)
  end
end
